/* 
 * Helper for setting time zone on records
 *
 * History
 * -------
   01/10/2019 Dan Carmen       Created
   11/14/2019 Dan Carmen       Remove ISDC fields  
   06/18/2021 Dan Carmen       Add Referral Accounts
   03/22/2023 Dan Carmen       Added address verifications
   05/24/2023 Dan Carmen       Verify State Code before setting legal state
   06/12/2023 Dan Carmen       Make sure picklist value is active in state codes
   07/13/2023 Dan Carmen       Add logic to handle non-US states/provinces
   10/13/2023 Dan Carmen       Remove double spaces from street addresses
   02/07/2024 Dan Carmen       Additional checks to make sure address is filled in, added Contact
   04/30/2024 Dan Carmen       Add additional testing


 */
public with sharing class TimeZoneHelper implements TriggerInterfaceC {

   public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      SObject[] recs = TriggerMethods.checkRecs('TimeZoneHelper', p_recs, oldMap, isBefore, isAfter, isDelete, null, null);
      // check what the type of the first record is
      System.debug('TimeZoneHelper.handleTrigger recs='+(recs != null ? recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter);
      if (recs != null && !recs.isEmpty()) {
         SObjectType recType = recs[0].getSObjectType();
         if (isBefore) {
            if (recType == Task.sObjectType) {
               checkRecords((Task[])recs);
            } else if (recType == Referral_Account__c.sObjectType) {
               checkRecords((Referral_Account__c[])recs, (Map<Id,Referral_Account__c>)oldMap);
            } else if (recType == Lead.sObjectType) {
               checkLeadsBefore((Lead[])recs, (Map<Id,Lead>)oldMap);
            } else if (recType == Account.sObjectType) {
               checkAccountsBefore((Account[])recs, (Map<Id,Account>)oldMap);
            } else if (recType == Contact.sObjectType) {
               checkCtctsBefore((Contact[])recs, (Map<Id,Contact>)oldMap);
            } else if (recType == User.sObjectType) {
               checkUsersBefore((User[])recs, (Map<Id,User>)oldMap);
            }
         } // if (isBefore
      } // if (recs != null
   } // handleTrigger
    
   public static Boolean CLEAR_INVALID_STATE = (Label.TimeZoneHelper_ClearIfNotValid=='Y');
    
   public static void checkUsersBefore(User[] recs, Map<Id,User> oldMap) {
      Set<String> zipSet = new Set<String>();
      User[] usrsToCheck = new User[]{};
      for (User usr : recs) {
         Boolean checkUsrZip = false;
         User oldUsr = (oldMap != null ? oldMap.get(usr.Id) : null);
         // make sure 2 character state code.
         usr.State = ZipCodeInformation.checkStateAbbrev(usr.State,CLEAR_INVALID_STATE);
         // default country to US
         if (String.isBlank(usr.Country)) {
            usr.Country = 'US';
         }
         if (String.isBlank(usr.PostalCode)) {
            // can't do anything else if we don't have postal codes - skip the rest
            continue;
         }
         checkStateCountry(usr, 'State', 'State', 'Country');
         
         if (String.isNotBlank(usr.PostalCode) 
                && (oldUsr == null || usr.PostalCode != oldUsr.PostalCode)
                    || String.isBlank(usr.City) || String.isBlank(usr.State)
                    || (ALWAYS_SET_CITY_STATE && oldUsr != null && usr.City != oldUsr.City)
                    || (ALWAYS_SET_CITY_STATE && oldUsr != null && usr.State != oldUsr.State)) {
            zipSet.add(usr.PostalCode.left(5));
            checkUsrZip = true;
         }
         if (checkUsrZip) {
            usrsToCheck.add(usr);
         }
          
      } // for (User usr : recs
       
      System.debug('checkUsersBefore recs='+recs.size()+' usrsToCheck='+usrsToCheck.size()+' zipSet='+zipSet.size());
      if (!zipSet.isEmpty()) {
         Map<String,Zip_Code_Information__c> zipMap = new Map<String,Zip_Code_Information__c>();
         Zip_Code_Information__c[] zcis = getZipInfo(zipSet);
         for (Zip_Code_Information__c zci : zcis) {
            zipMap.put(zci.Name, zci);
         }
         for (User usr : usrsToCheck) {
            checkCityState(usr, usr.PostalCode, zipMap, 'City', 'State',null,null);
         } // for (User usr : usrsToCheck

      } // if (!zipSet.isEmpty

   } // checkUsersBefore
    
   // MailingAddress
   // OtherAddress
   public static void checkCtctsBefore(Contact[] recs, Map<Id,Contact> oldMap) {
      Set<String> zipSet = new Set<String>();
      Contact[] ctctsToCheck = new Contact[]{};
      for (Contact ctct : recs) {
         Boolean checkCtctZip = false;
         Contact oldCtct = (oldMap != null ? oldMap.get(ctct.Id) : null);
         // make sure 2 character state code.
         ctct.MailingState = ZipCodeInformation.checkStateAbbrev(ctct.MailingState,CLEAR_INVALID_STATE);
         ctct.OtherState = ZipCodeInformation.checkStateAbbrev(ctct.OtherState,CLEAR_INVALID_STATE);
         // default country to US
         if (String.isBlank(ctct.MailingCountry)) {
            ctct.MailingCountry = 'US';
         }
         if (String.isBlank(ctct.OtherCountry)) {
            ctct.OtherCountry = 'US';
         }
         if (String.isBlank(ctct.MailingPostalCode) && String.isBlank(ctct.OtherPostalCode)) {
            // can't do anything else if we don't have postal codes - skip the rest
            continue;
         }
         checkStateCountry(ctct, 'MailingState', 'MailingState', 'MailingCountry');
         checkStateCountry(ctct, 'OtherState', 'OtherState', 'OtherCountry');
         
         if (String.isNotBlank(ctct.MailingPostalCode) 
                && (oldCtct == null || ctct.MailingPostalCode != oldCtct.MailingPostalCode)
                    || String.isBlank(ctct.MailingCity) || String.isBlank(ctct.MailingState)
                    || (ALWAYS_SET_CITY_STATE && oldCtct != null && ctct.MailingCity != oldCtct.MailingCity)
                    || (ALWAYS_SET_CITY_STATE && oldCtct != null && ctct.MailingState != oldCtct.MailingState)) {
            zipSet.add(ctct.MailingPostalCode.left(5));
            checkCtctZip = true;
         }
         if (String.isNotBlank(ctct.OtherPostalCode) 
                && (oldCtct == null || ctct.OtherPostalCode != oldCtct.OtherPostalCode)
                    || String.isBlank(ctct.OtherCity) || String.isBlank(ctct.OtherState)
                    || (ALWAYS_SET_CITY_STATE && oldCtct != null && ctct.OtherCity != oldCtct.OtherCity)
                    || (ALWAYS_SET_CITY_STATE && oldCtct != null && ctct.OtherState != oldCtct.OtherState)) {
            zipSet.add(ctct.OtherPostalCode.left(5));
            checkCtctZip = true;
         }
         if (checkCtctZip) {
            ctctsToCheck.add(ctct);
         }
          
      } // for (Contact ctct : recs
       
      System.debug('checkCtctsBefore recs='+recs.size()+' ctctsToCheck='+ctctsToCheck.size()+' zipSet='+zipSet.size());
      if (!zipSet.isEmpty()) {
         Map<String,Zip_Code_Information__c> zipMap = new Map<String,Zip_Code_Information__c>();
         Zip_Code_Information__c[] zcis = getZipInfo(zipSet);
         for (Zip_Code_Information__c zci : zcis) {
            zipMap.put(zci.Name, zci);
         }
         for (Contact ctct : ctctsToCheck) {
            checkCityState(ctct, ctct.MailingPostalCode, zipMap, 'MailingCity', 'MailingState',null,null);
            checkCityState(ctct, ctct.OtherPostalCode, zipMap, 'OtherCity', 'OtherState','OtherLatitude','OtherLongitude');
         } // for (Contact ctct : ctctsToCheck

      } // if (!zipSet.isEmpty

   } // checkCtctsBefore
    
   public static void checkAccountsBefore(Account[] recs, Map<Id,Account> oldMap) {
      Set<String> zipSet = new Set<String>();
      Account[] acctsToCheck = new Account[]{};
       
      for (Account acct : recs) {
         Boolean checkAcctZip = false;
         Account oldAcct = (oldMap != null ? oldMap.get(acct.Id) : null);
         // make sure 2 character state code.
         acct.ShippingState = ZipCodeInformation.checkStateAbbrev(acct.ShippingState,CLEAR_INVALID_STATE);
         acct.BillingState = ZipCodeInformation.checkStateAbbrev(acct.BillingState,CLEAR_INVALID_STATE);
         acct.Legal_State__c = ZipCodeInformation.checkStateAbbrev(acct.Legal_State__c,true);
         // default country to US
         Boolean countryChanged = false;
         if (String.isBlank(acct.ShippingCountry)) {
            countryChanged = true;
            acct.ShippingCountry = 'US';
         }
         if (String.isBlank(acct.BillingCountry)) {
            countryChanged = true;
            acct.BillingCountry = 'US';
         }
         // if the address was previously validated and it changed significantly enough, then 
         if (oldAcct != null) {
            if (acct.BillingValidated__c
                 && (String.isBlank(acct.BillingPostalCode) || String.isBlank(acct.BillingStreet)
                     || acct.BillingStreet != oldAcct.BillingStreet
                     || String.isBlank(oldAcct.BillingPostalCode)
                     || acct.BillingPostalCode.left(5) != oldAcct.BillingPostalCode.left(5))) {
               acct.BillingValidated__c = false;
               acct.BillingValidationOverride__c = false;
            }
            if (acct.ShippingValidated__c
                 && (String.isBlank(acct.ShippingPostalCode) || String.isBlank(acct.ShippingStreet)
                     || acct.ShippingStreet != oldAcct.ShippingStreet
                     || String.isBlank(oldAcct.ShippingPostalCode)
                     || acct.ShippingPostalCode.left(5) != oldAcct.ShippingPostalCode.left(5))) {
               acct.ShippingValidated__c = false;
               acct.ShippingValidationOverride__c = false;
            }
         } // if (oldAcct != null
         countryChanged = (countryChanged || (String.isNotBlank(acct.ShippingCountry) && (oldAcct == null || acct.ShippingCountry != oldAcct.ShippingCountry)));
         countryChanged = (countryChanged || (String.isNotBlank(acct.BillingCountry) && (oldAcct == null || acct.BillingCountry != oldAcct.BillingCountry)));
         if (String.isBlank(acct.LegalAddress__CountryCode__s)) {
            acct.LegalAddress__CountryCode__s = 'US';
         }
         // set the legal address composite fields from the old legal fields
         if (String.isNotBlank(acct.Legal_Street__c) && String.isBlank(acct.LegalAddress__Street__s)) {
            acct.LegalAddress__Street__s = acct.Legal_Street__c;
         }
         if (String.isNotBlank(acct.Legal_City__c) && String.isBlank(acct.LegalAddress__City__s)) {
            acct.LegalAddress__City__s = acct.Legal_City__c;
         }
         checkStateCountry(acct, 'Legal_State__c', 'LegalAddress__StateCode__s', 'LegalAddress__CountryCode__s');

         // remove double spaces from address lines
         checkStreet(acct, 'LegalAddress__Street__s');
         checkStreet(acct, 'ShippingStreet');
         checkStreet(acct, 'BillingStreet');

         if (countryChanged) {
            // verify the non-legal country fields
            String countryCode = verifyCountryCode(acct.ShippingState);
            if (countryCode != null && countryCode != acct.ShippingCountry) {
               acct.ShippingCountry = countryCode;
            }
            countryCode = verifyCountryCode(acct.BillingState);
            if (countryCode != null && countryCode != acct.BillingCountry) {
               acct.BillingCountry = countryCode;
            }
         }
         if (String.isNotBlank(acct.Legal_Postal_Code__c) && String.isBlank(acct.LegalAddress__PostalCode__s)) {
            acct.LegalAddress__PostalCode__s = acct.Legal_Postal_Code__c;
         }
         // populate the Owner_Zip_Code__c field
         AccountMethods.checkZipFields(acct, oldAcct);
         Boolean missingCityState = (String.isNotBlank(acct.ShippingPostalCode) 
                                        && (String.isBlank(acct.ShippingCity) || String.isBlank(acct.ShippingState)));
         missingCityState = (missingCityState || (String.isNotBlank(acct.BillingPostalCode) 
                                        && (String.isBlank(acct.BillingCity) || String.isBlank(acct.BillingState))));
         missingCityState = (missingCityState || (String.isNotBlank(acct.LegalAddress__PostalCode__s) 
                                        && (String.isBlank(acct.LegalAddress__City__s) || String.isBlank(acct.LegalAddress__StateCode__s))));
         if (String.isNotBlank(acct.Owner_Zip_Code__c) && (oldAcct == null || missingCityState || String.isBlank(acct.TimeZoneAbbrev__c) 
                                                           || (oldAcct != null && acct.Owner_Zip_Code__c != oldAcct.Owner_Zip_Code__c) 
                                                         )) {
            zipSet.add(acct.Owner_Zip_Code__c);                                              
            checkAcctZip = true;
         } // if (String.isNotBlank
         System.debug('checkAccountsBefore checkAcctZip='+checkAcctZip);
         if (String.isNotBlank(acct.LegalAddress__PostalCode__s) && (oldAcct == null || acct.LegalAddress__PostalCode__s != oldAcct.LegalAddress__PostalCode__s)) {
            zipSet.add(acct.LegalAddress__PostalCode__s.left(5));
            checkAcctZip = true;
         }
         if (String.isNotBlank(acct.ShippingPostalCode) && (oldAcct == null || acct.ShippingPostalCode != oldAcct.ShippingPostalCode)) {
            zipSet.add(acct.ShippingPostalCode.left(5));
            checkAcctZip = true;
         }
         if (String.isNotBlank(acct.BillingPostalCode) && (oldAcct == null || acct.BillingPostalCode != oldAcct.BillingPostalCode)) {
            zipSet.add(acct.BillingPostalCode.left(5));
            checkAcctZip = true;
         }

         if (checkAcctZip) {
            acctsToCheck.add(acct);
         }
         System.debug('checkAccountsBefore acct='+acct.BillingStreet+' oldAcct='+(oldAcct != null ? oldAcct.BillingStreet : 'No oldAcct'));
         // TODO - do we need to recalc if an address changes after it's populated? Not sure the extent of this. 
         if ((String.isBlank(acct.ShippingUUID__c) && String.isNotBlank(acct.ShippingStreet) && String.isNotBlank(acct.ShippingPostalCode))
             || (String.isBlank(acct.EnterpriseShippingId__c) && oldAcct != null && (acct.ShippingStreet != oldAcct.ShippingStreet || acct.ShippingPostalCode != oldAcct.ShippingPostalCode))
             || (String.isBlank(acct.BillingUUID__c) && String.isNotBlank(acct.BillingStreet) && String.isNotBlank(acct.BillingPostalCode))
             || (String.isBlank(acct.EnterpriseBillingId__c) && oldAcct != null && (acct.BillingStreet != oldAcct.BillingStreet || acct.BillingPostalCode != oldAcct.BillingPostalCode))
            ) {
            checkAddrUUID(acct, oldAcct);
         }
      } // for (Account acct : recs
                      
      System.debug('checkAccountsBefore recs='+recs.size()+' acctsToCheck='+acctsToCheck.size()+' zipSet='+zipSet.size());
      if (!zipSet.isEmpty()) {
         Map<String,Zip_Code_Information__c> zipMap = new Map<String,Zip_Code_Information__c>();
         Zip_Code_Information__c[] zcis = getZipInfo(zipSet);
         for (Zip_Code_Information__c zci : zcis) {
            zipMap.put(zci.Name, zci);
         }
         for (Account acct : acctsToCheck) {
            Zip_Code_Information__c zci = (String.isNotBlank(acct.Owner_Zip_Code__c) ? zipMap.get(acct.Owner_Zip_Code__c) : null);
            if (zci != null) {
               acct.TimeZoneAbbrev__c = zci.TimeZoneAbbrev__c;
               acct.TimeZoneName__c = zci.TimeZoneName__c;
            }
            checkCityState(acct, acct.LegalAddress__PostalCode__s, zipMap, 'LegalAddress__City__s', 'LegalAddress__StateCode__s',null,null);
            checkCityState(acct, acct.ShippingPostalCode, zipMap, 'ShippingCity', 'ShippingState',null,null);
            checkCityState(acct, acct.BillingPostalCode, zipMap, 'BillingCity', 'BillingState',null,null);
         } // for (Account acct : recs

      } // if (!zipSet.isEmpty
   } // checkAccountsBefore
    
   public static void checkStreet(Account acct, String fldName) {
      String streetValue = (String)acct.get(fldName);
      if (String.isNotBlank(streetValue) && streetValue.contains(' ')) {
         while (streetValue.contains('  ')) {
            streetValue = streetValue.replaceAll('  ',' ');
         }
         acct.put(fldName,streetValue);
      } // if (String.isNotBlank(returnValue)
   } // checkStreet
    
   public static void checkStateCountry(SObject rec, String stateFldChk, String stateFldUpdate, String countryFld) {
      // if they're the same field, always update.
      // If they're different fields, only update if the update field is null
      Boolean fldCheck = ((stateFldChk == stateFldUpdate)
                           || (stateFldChk != stateFldUpdate && rec.get(stateFldUpdate) == null));
      System.debug('checkStateCountry fldCheck='+fldCheck);
      String state = (String)rec.get(stateFldChk);
      if (String.isNotBlank(state) && state.length()==2 && fldCheck) {
         String checkState = verifyStateCode(state);
         if (checkState != null) {
            String countryCode = verifyCountryCode(checkState);
            if (countryCode != null) {
               rec.put(countryFld,countryCode);
               }
            rec.put(stateFldUpdate,checkState);
         }
      } // if (String.isNotBlank(state) && state.length
   } // checkStateCountry
    
    public static String verifyStateCode(String valueToCheck) {
        String upperValue = (String.isNotBlank(valueToCheck) ? valueToCheck.toUpperCase() : null);
        if (upperValue != null) {
           Set<String> validStateSet = (Set<String>)CacheManager.getOrg('TimeZoneHelperValidStateCodes');
           if (validStateSet == null) {
              validStateSet = new Set<String>();
              Schema.DescribeFieldResult fieldResult = Account.LegalAddress__StateCode__s.getDescribe();
              List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
              for (Schema.PicklistEntry pickVal : ple){
                 if (pickval.isActive()) {
                    validStateSet.add(pickVal.getValue());
                 }
              }
              CacheManager.putOrg('TimeZoneHelperValidStateCodes',validStateSet);
           } // if (validStateSet == null
           upperValue = (validStateSet.contains(upperValue) ? upperValue : null);
           System.debug('verifyStateCode valueToCheck='+valueToCheck+' upperValue='+upperValue);
        } // if (upperValue != null
        return upperValue;
    } // verifyStateCode
    
    public static Map<String,String> stateCountryMap = null;
    
    public static String verifyCountryCode(String stateCode) {
       if (String.isNotBlank(stateCode)) {
          if (stateCountryMap == null) {
             stateCountryMap = (Map<String,String>)CacheManager.getOrg('TimeZoneHelperStateCountryCodes');
          }
          if (stateCountryMap == null) {
             stateCountryMap = new Map<String,String>();
             for (Abbreviation__mdt abbrev : Abbreviation__mdt.getAll().values()) {
                if (String.isNotBlank(abbrev.Country__c)) {
                   stateCountryMap.put(abbrev.Abbrev__c,abbrev.Country__c);
                }
             } // for (Abbreviation__mdt abbrev
             System.debug('verifyCountryCode stateCountryMap='+stateCountryMap.size());
             CacheManager.putOrg('TimeZoneHelperStateCountryCodes',stateCountryMap);
          }
       } // if (String.isNotBlank(stateCode
       String country = (stateCountryMap != null ? stateCountryMap.get(stateCode) : null);
       return (country != null ? country : 'US');
    } // verifyCountryCode
    
   // are we always going to set the city and state based on the zip code? 
   // This could change what the user entered, but it should be more accurate (and account for spelling)
   public static Boolean ALWAYS_SET_CITY_STATE=(Label.TimeZoneHelper_AlwaysSetCityState=='Y');
    
   public static void checkCityState(SObject rec, String zipCode, Map<String,Zip_Code_Information__c> zipMap, String cityFldName, String stateFldName
                                     ,String latFld, String longFld) {
      Zip_Code_Information__c zci = (String.isNotBlank(zipCode) ? zipMap.get(zipCode.left(5)) : null);
      System.debug('checkCityState ALWAYS_SET_CITY_STATE='+ALWAYS_SET_CITY_STATE+' rec='+rec.Id+' zipCode='+zipCode+' cityFldName='+cityFldName+' zci='+zci);
      if (zci != null) {
         if (String.isNotBlank(zci.City__c) && (rec.get(cityFldName) == null || (ALWAYS_SET_CITY_STATE && String.valueOf(rec.get(cityFldName)) != zci.City__c))) {
            System.debug('checkCityState updating city');
            rec.put(cityFldName, zci.City__c);
         }
         if (String.isNotBlank(zci.State__c) && (rec.get(stateFldName) == null || (ALWAYS_SET_CITY_STATE && String.valueOf(rec.get(stateFldName)) != zci.State__c))) {
            System.debug('checkCityState updating state');
            rec.put(stateFldName, zci.State__c);
         }
         if (latFld != null) {
            rec.put(latFld, zci.Zip_Geo__Latitude__s);
         }
         if (longFld != null) {
            rec.put(longFld, zci.Zip_Geo__Longitude__s);
         }
      }
   } // checkCityState
   
   // TODO - do we need to check if an address changes?
   public static void checkAddrUUID(Account acct, Account oldAcct) {
      // if we don't want this trigger execution to touch the address ids.s
      if (acct.SkipAddressIdCheck__c) {
         acct.SkipAddressIdCheck__c = false;
         return;
      }
      Boolean billUUIDChanged = (oldAcct != null && String.isNotBlank(acct.BillingUUID__c) && acct.BillingUUID__c != oldAcct.BillingUUID__c);
      Boolean shipUUIDChanged = (oldAcct != null && String.isNotBlank(acct.ShippingUUID__c) && acct.ShippingUUID__c != oldAcct.ShippingUUID__c);
      System.debug('checkAddrUUID billUUIDChanged='+billUUIDChanged+' shipUUIDChanged='+shipUUIDChanged);
      // if the ids are set as part of this transaction, then don't update anything.
      if (billUUIDChanged || shipUUIDChanged) {
         return;
      }
      String shipPostal = (String.isNotBlank(acct.ShippingPostalCode) ? acct.ShippingPostalCode.left(5) : null);
      String oldShipPostal = (oldAcct != null && String.isNotBlank(oldAcct.ShippingPostalCode) ? oldAcct.ShippingPostalCode.left(5) : null);
      String billPostal = (String.isNotBlank(acct.BillingPostalCode) ? acct.BillingPostalCode.left(5) : null);
      String oldBillPostal = (oldAcct != null && String.isNotBlank(oldAcct.BillingPostalCode) ? oldAcct.BillingPostalCode.left(5) : null);
      
       
      String shipStreet = EZOnboardingRegistration.formatAddress(acct.ShippingStreet);
      String oldShipStreet = (oldAcct != null ? EZOnboardingRegistration.formatAddress(oldAcct.ShippingStreet) : null);
      String billstreet = EZOnboardingRegistration.formatAddress(acct.BillingStreet);
      String oldBillStreet = (oldAcct != null ? EZOnboardingRegistration.formatAddress(oldAcct.BillingStreet) : null);
      System.debug('checkAddrUUID shipStreet='+shipStreet+' oldShipStreet='+oldShipStreet);
      System.debug('checkAddrUUID billstreet='+billstreet+' oldBillStreet='+oldBillStreet);
       
      Boolean billChanged = (String.isBlank(acct.EnterpriseBillingId__c) && (oldAcct == null || (billstreet != oldBillStreet || billPostal != oldBillPostal)));
      Boolean shipChanged = (String.isBlank(acct.EnterpriseShippingId__c) && (oldAcct == null || (shipStreet != oldShipStreet || shipPostal != oldShipPostal)));
      System.debug('checkAddrUUID billChanged='+billChanged+' shipChanged='+shipChanged);
      if (!billChanged && !shipChanged) {
         return;
      }
      // EnterpriseBillingId__c
      // EnterpriseShippingId__c
      Boolean billAndShipMatch = (String.isNotBlank(shipStreet) && shipStreet ==billstreet
                                  && shipPostal != null && shipPostal == billPostal);
      // do the old addresses match
      Boolean oldBillAndShipMatch = (oldAcct != null && String.isNotBlank(oldShipStreet) && oldShipStreet ==oldBillStreet
                                  && String.isNotBlank(oldShipPostal) && oldShipPostal == oldBillPostal);
      System.debug('checkAddrUUID billAndShipMatch='+billAndShipMatch+' oldBillAndShipMatch='+oldBillAndShipMatch);
       
      System.debug('checkAddrUUID acct='+acct.Name+' billAndShipMatch='+billAndShipMatch);
      if (billAndShipMatch && (String.isNotBlank(acct.BillingUUID__c) || String.isNotBlank(acct.ShippingUUID__c))) {
         System.debug('checkAddrUUID case 1');
         Boolean handled=false;
         // if the addresses match and one of them already have a UUID
         if (String.isNotBlank(acct.BillingUUID__c) && (String.isBlank(acct.ShippingUUID__c) || shipChanged)) {
            acct.ShippingUUID__c = acct.BillingUUID__c;
            handled=true;
         } else if ((String.isBlank(acct.BillingUUID__c) || billChanged) && String.isNotBlank(acct.ShippingUUID__c)) {
            acct.BillingUUID__c = acct.ShippingUUID__c;
            handled=true;
         }
         if (handled) {
            System.debug('checkAddrUUID case 1 handled');
            return;
         }
      } else if (billAndShipMatch && String.isBlank(acct.BillingUUID__c) && String.isBlank(acct.ShippingUUID__c)) {
         System.debug('checkAddrUUID case 2');
         // if the addresses match and neither have a UUID
         String uuid = System.UUID.randomUUID().toString();
         acct.ShippingUUID__c = uuid;
         acct.BillingUUID__c = uuid;
         return;
      } else if (String.isBlank(acct.BillingUUID__c) || String.isBlank(acct.ShippingUUID__c)) {
         System.debug('checkAddrUUID case 3');
         // the addresses don't match. Get a UUID for each if they're populated
         if (String.isBlank(acct.BillingUUID__c) && String.isNotBlank(acct.BillingStreet) && String.isNotBlank(acct.BillingPostalCode)) {
            System.debug('checkAddrUUID case 3a');
            acct.BillingUUID__c=System.UUID.randomUUID().toString();
         }
         if (String.isBlank(acct.ShippingUUID__c) && String.isNotBlank(acct.ShippingStreet) && String.isNotBlank(acct.ShippingPostalCode)) {
            System.debug('checkAddrUUID case 3b');
            acct.ShippingUUID__c=System.UUID.randomUUID().toString();
         }
         return;
      }
       
      // if we already have ids for both fields, evaluate
      // if the old addresses matches, but the new ones do not
      if ((oldBillAndShipMatch && !billAndShipMatch) || (!billAndShipMatch && acct.ShippingUUID__c == acct.BillingUUID__c)) {
         System.debug('checkAddrUUID case 4');
          if (billChanged) {
             // assign a new UUID
             acct.BillingUUID__c = System.UUID.randomUUID().toString();
          }
          if (shipChanged) {
             acct.ShippingUUID__c = System.UUID.randomUUID().toString();
          }
          // we don't need to do anything else here
          return;
      } else if (!oldBillAndShipMatch && billAndShipMatch) {
         System.debug('checkAddrUUID case 5');
         if (shipChanged) {
            acct.ShippingUUID__c = acct.BillingUUID__c;
         } else if (billChanged) {
            acct.BillingUUID__c = acct.ShippingUUID__c;
         }
      }

   } // checkAddrUUID
    
   public static void checkLeadsBefore(Lead[] recs, Map<Id,Lead> oldMap) {
      Map<String,Lead[]> leadByZipMap = new Map<String,Lead[]>();
      for (Lead ld : recs) {
         Lead oldLd = (oldMap != null ? oldMap.get(ld.Id) : null);
         // if it's an insert or the state changes
         if (String.isNotBlank(ld.State) && (oldLd == null || (ld.State != oldLd.State))) {
            ld.State = ZipCodeInformation.checkStateAbbrev(ld.State,CLEAR_INVALID_STATE);
         }
          
         if (String.isBlank(ld.Country)) {
            ld.Country = 'US';
         }
         checkStateCountry(ld, 'State', 'State', 'Country');
         // if it's an insert or the country changes
         //if (String.isNotBlank(ld.Country) && (oldLd == null || (ld.Country != oldLd.Country))) {
         //   ld.Country = verifyCountryCode(ld.State);
         //}
         
         if (String.isNotBlank(ld.PostalCode)
              && (String.isBlank(ld.TimeZoneAbbrev__c)
                   || (ALWAYS_SET_CITY_STATE && oldLd == null)
                   || String.isBlank(ld.City)
                   || String.isBlank(ld.State)
                   || (oldLd != null && ld.PostalCode != oldLd.PostalCode)
                   || (ALWAYS_SET_CITY_STATE && oldLd != null && ld.City != oldLd.City)
                   || (ALWAYS_SET_CITY_STATE && oldLd != null && ld.State != oldLd.State))) {
            String postalCode = Utilities.checkPostalCode(ld.PostalCode,null);
            if (String.IsNotBlank(postalCode)) {
               Lead[] leadList = (leadByZipMap.containsKey(postalCode) ? leadByZipMap.get(postalCode) : new Lead[]{});
               leadList.add(ld);
               leadByZipMap.put(postalCode,leadList);
            }
         } // if (String.isNotBlank
      } // for (Lead ld
      System.debug('checkLeadsBefore recs='+recs.size()+' leadByZipMap='+leadByZipMap.size());
      if (!leadByZipMap.isEmpty()) {
         Zip_Code_Information__c[] zcis = getZipInfo(leadByZipMap.keySet()); 
         for (Zip_Code_Information__c zci : zcis) {
            Lead[] lds = leadByZipMap.get(zci.Name);
            if (lds != null) {
               for (Lead ld : lds) {
                  ld.TimeZoneAbbrev__c = zci.TimeZoneAbbrev__c;
                  ld.TimeZoneName__c = zci.TimeZoneName__c;
                  if (String.isNotBlank(zci.City__c)) {
                     ld.City = zci.City__c;
                  }
                  if (String.isNotBlank(zci.State__c)) {
                     ld.State = zci.State__c;
                  }
               }
            }
         } // for (Zip_Code_Information__c zci
      } // if (!leadByZipMap.isEmpty
      
      leadByZipMap.clear();
      for (Lead ld : recs) {
         Lead oldLd = (oldMap != null ? oldMap.get(ld.Id) : null);
         if (String.isNotBlank(ld.Phone) && (String.isBlank(ld.TimeZoneAbbrev__c) 
                                             || (oldLd != null && ld.Phone != oldLd.Phone))) {
            String tempPhone = Utilities.removeExtraChars(ld.Phone, Utilities.ALL_NUMBERS);
            System.debug('checkLeadsBefore phone='+ld.Phone+' tempPhone='+tempPhone);
            // make sure it's long enough to be a phone with area code
            if (String.isNotBlank(tempPhone) && tempPhone.length() >= 10) {
               String areaCd = tempPhone.left(3);
               Lead[] leadList = (leadByZipMap.containsKey(areaCd) ? leadByZipMap.get(areaCd) : new Lead[]{});
               leadList.add(ld);
               leadByZipMap.put(areaCd,leadList);
            }
         } // if (String.isNotBlank
      } // for (Lead ld : recs
       
      if (!leadByZipMap.isEmpty()) {
         AreaCode__c[] acs = [SELECT Id, Name, TimeZoneName__c, TimeZoneAbbrev__c FROM AreaCode__c WHERE NAME IN :leadByZipMap.keySet()];
         for (AreaCode__c ac : acs) {
            Lead[] lds = leadByZipMap.get(ac.Name);
            if (lds != null) {
               for (Lead ld : lds) {
                  ld.TimeZoneAbbrev__c = ac.TimeZoneAbbrev__c;
                  ld.TimeZoneName__c = ac.TimeZoneName__c;
               } // for (Lead ld : lds
            } // if (lds != null
         } // for (AreaCode__c ac
      } // if (!leadByZipMap.isEmpty
       
   } // checkLeadsBefore
    
    public static Zip_Code_Information__c[] getZipInfo(Set<String> zipSet) {
       Zip_Code_Information__c[] zcis = [Select Id, Name, City__c, State__c, TimeZoneAbbrev__c, TimeZoneName__c 
                                                 , Zip_Geo__Latitude__s, Zip_Geo__Longitude__s
                                             from Zip_Code_Information__c where Name in :zipSet];
       return zcis;
    } // getZipInfo

   public static void checkRecords(Referral_Account__c[] recs, Map<Id,Referral_Account__c> oldMap) {
      Map<String,Referral_Account__c[]> refAcctsByZipMap = new Map<String,Referral_Account__c[]>();
      for (Referral_Account__c refAcct : recs) {
         Referral_Account__c oldRef = (oldMap != null ? oldMap.get(refAcct.Id) : null);
         // if it's still blank, default to US
         if (String.isBlank(refAcct.Address__CountryCode__s)) {
            refAcct.Address__CountryCode__s = 'US';
         }
         // populating the composite field in here is transition code. If we fully move over to this new field will need to revamp this code.
         if ((String.isBlank(refAcct.Address__CountryCode__s) || String.isBlank(refAcct.Address__StateCode__s))
                && (String.isNotBlank(refAcct.State_Province__c) && (oldRef == null || refAcct.State_Province__c != oldRef.State_Province__c))) {
            String checkState = verifyStateCode(refAcct.State_Province__c);
            if (checkState != null) {
               String countryCode = verifyCountryCode(checkState);
               if (countryCode != null) {
                   refAcct.Address__CountryCode__s = countryCode;
               }
               refAcct.Address__StateCode__s = checkState;
            }
         } // if (String.isBlank(refAcct.Address__CountryCode__s
          
         // populate the street on the composite address field
         if (String.isNotBlank(refAcct.Street_Address_1__c) 
                && (String.isBlank(refAcct.Address__Street__s) || (oldRef != null && refAcct.Street_Address_1__c != oldRef.Street_Address_1__c)
                       || (oldRef != null && refAcct.Street_Address_2__c != oldRef.Street_Address_2__c))) {
            String street = refAcct.Street_Address_1__c + 
                      (String.isNotBlank(refAcct.Street_Address_2__c) ? '\n'+refAcct.Street_Address_2__c : '' );
            refAcct.Address__Street__s = street; 
         } // if (String.isNotBlank(refAcct.Street_Address_1__c
         // populate the city on the composite address field
         if (String.isNotBlank(refAcct.City__c) && (String.isBlank(refAcct.Address__City__s) || (oldRef != null && refAcct.City__c != oldRef.City__c))) {
            refAcct.Address__City__s = refAcct.City__c;
         }
         // populate the postal code on the composite address field
         if (String.isNotBlank(refAcct.Zip_Postal_Code__c) 
                && (String.isBlank(refAcct.Address__PostalCode__s) || (oldRef != null && refAcct.Zip_Postal_Code__c != oldRef.Zip_Postal_Code__c))) {
            refAcct.Address__PostalCode__s = refAcct.Zip_Postal_Code__c;
         }
         // in case in the future the zips might be different
         Set<String> zipSet = new Set<String>();
         if (String.isNotBlank(refAcct.Zip_Postal_Code__c)
               && (String.isBlank(refAcct.TimeZoneAbbrev__c) 
                   || (ALWAYS_SET_CITY_STATE && oldRef == null)
                   || String.isBlank(refAcct.State_Province__c)
                   || String.isBlank(refAcct.City__c)
                   || (oldRef != null && refAcct.Zip_Postal_Code__c != oldRef.Zip_Postal_Code__c)
                   || (ALWAYS_SET_CITY_STATE && oldRef != null && refAcct.City__c != oldRef.City__c)
                   || (ALWAYS_SET_CITY_STATE && oldRef != null && refAcct.State_Province__c != oldRef.State_Province__c))) {
            // make sure we're only getting the 5 character postal code
            zipSet.add(refAcct.Zip_Postal_Code__c.left(5));
         } // if (String.isNotBlank(refAcct.Zip_Postal_Code__c)
          
         if (String.isNotBlank(refAcct.Address__PostalCode__s)
               && (String.isBlank(refAcct.TimeZoneAbbrev__c) 
                   || (ALWAYS_SET_CITY_STATE && oldRef == null)
                   || String.isBlank(refAcct.Address__StateCode__s)
                   || String.isBlank(refAcct.Address__City__s)
                   || (oldRef != null && refAcct.Address__PostalCode__s != oldRef.Address__PostalCode__s)
                   || (ALWAYS_SET_CITY_STATE && oldRef != null && refAcct.Address__City__s != oldRef.Address__City__s)
                   || (ALWAYS_SET_CITY_STATE && oldRef != null && refAcct.Address__StateCode__s != oldRef.Address__StateCode__s))) {
            // make sure we're only getting the 5 character postal code
            zipSet.add(refAcct.Address__PostalCode__s.left(5));
         } // if (String.isNotBlank(refAcct.Zip_Postal_Code__c)
         checkAddToMap(zipSet, refAcct, refAcctsByZipMap);
          
      } // for (Referral_Account__c refAcct : recs
      System.debug('checkRecords recs='+recs.size()+' refAcctsByZipMap='+refAcctsByZipMap.size());
      if (!refAcctsByZipMap.isEmpty()) {
         Zip_Code_Information__c[] zcis = [Select Id, Name, City__c, State__c, TimeZoneAbbrev__c from Zip_Code_Information__c where Name in :refAcctsByZipMap.keySet()];
         System.debug('checkRecords zcis='+zcis.size());
         for (Zip_Code_Information__c zci : zcis) {
            Referral_Account__c[] refAccts = refAcctsByZipMap.get(zci.Name);
            if (refAccts != null) {
               for (Referral_Account__c refAcct : refAccts) {
                  if (String.isNotBlank(refAcct.Zip_Postal_Code__c) && zci.Name == refAcct.Zip_Postal_Code__c.left(5)) {
                     //refAcct.TimeZoneAbbrev__c = zci.TimeZoneAbbrev__c;
                     if (String.isNotBlank(zci.State__c) && (String.isBlank(refAcct.State_Province__c) 
                            || (ALWAYS_SET_CITY_STATE && refAcct.State_Province__c != zci.State__c))) {
                        refAcct.State_Province__c = zci.State__c;
                     }
                     if (String.isNotBlank(zci.City__c) && (String.isBlank(refAcct.City__c) 
                            || (ALWAYS_SET_CITY_STATE && refAcct.City__c != zci.City__c))) {
                        refAcct.City__c = zci.City__c;
                     }
                  } // if (String.isNotBlank(refAcct.Zip_Postal_Code__c
                  if (String.isNotBlank(refAcct.Address__PostalCode__s) && zci.Name == refAcct.Address__PostalCode__s.left(5)) {
                     refAcct.TimeZoneAbbrev__c = zci.TimeZoneAbbrev__c;
                     if (String.isNotBlank(zci.State__c) && (String.isBlank(refAcct.Address__StateCode__s) 
                            || (ALWAYS_SET_CITY_STATE && refAcct.Address__StateCode__s != zci.State__c))) {
                        refAcct.Address__StateCode__s = zci.State__c;
                     }
                     if (String.isNotBlank(zci.City__c) && (String.isBlank(refAcct.Address__City__s) 
                            || (ALWAYS_SET_CITY_STATE && refAcct.Address__City__s != zci.City__c))) {
                        refAcct.Address__City__s = zci.City__c;
                     }
                  } // if (String.isNotBlank(refAcct.Zip_Postal_Code__c
                   
               } // for (Referral_Account__c refAcct : refAccts
            } // if (refAccts != null
         } // for (Zip_Code_Information__c zci : zcis
      } // if (!refAcctsByZipMap.isEmpty
   } // checkRecords
   
   public static void checkAddToMap(Set<String> zipSet, Referral_Account__c refAcct, Map<String,Referral_Account__c[]> refAcctsByZipMap) {
      for (String zip : zipSet) {
         addToMap(zip, refAcct, refAcctsByZipMap);
      }
   } // checkAddToMap
    
   public static void addToMap(String zip, Referral_Account__c refAcct, Map<String,Referral_Account__c[]> refAcctsByZipMap) {
      Referral_Account__c[] refAccts = (refAcctsByZipMap.containsKey(zip) ? refAcctsByZipMap.get(zip) : new Referral_Account__c[]{});
      refAccts.add(refAcct);
      refAcctsByZipMap.put(zip,refAccts);
   } // addToMap

   // if a task is linked to an account or lead, or there's a phone number
   public static void checkRecords(Task[] recs) {
      // If a DialSource task - we will get the dialsource record to get the inbound caller id
      // we don't need a list for tasks but to keep them consistent
      Map<String,Task[]> dsTaskMap = new Map<String,Task[]>();
      // tasks that we will search by area code to attempt to find the time zone
      Map<String,Task[]> areaCdMap = new Map<String,Task[]>();
      Map<String,Task[]> leadIdMap = new Map<String,Task[]>();
      Map<String,Task[]> ctctIdMap = new Map<String,Task[]>();
      Map<String,Task[]> acctIdMap = new Map<String,Task[]>();
      
      Task[] tasksToCheck = new Task[]{};
      for (Task tsk : recs) {
         // see if there's enough information on the task to get the time zone
         if (String.isBlank(tsk.TimeZoneAbbrev__c)
                && (tsk.WhoId != null || tsk.WhatId != null || tsk.AccountId != null
                         || (tsk.CallType == 'Inbound' && tsk.DS_Denali__DialSource_Action__c != null))) {
            // these are all of the tasks we'll be checking
            tasksToCheck.add(tsk);
            String tskWhoId = String.valueOf(tsk.WhoId);
            if (String.isNotBlank(tskWhoId) && (tskWhoId.startsWith(ObjectHelper.PREFIX_CONTACT) || tskWhoId.startsWith(ObjectHelper.PREFIX_LEAD))) {
               addToMap(tsk.WhoId, tsk, (tskWhoId.startsWith(ObjectHelper.PREFIX_CONTACT) ? ctctIdMap : leadIdMap));
            }
         
            String tskWhatId = String.valueOf(tsk.WhatId);
            if (String.isNotBlank(tskWhatId) && tskWhatId.startsWith(ObjectHelper.PREFIX_ACCOUNT) || tsk.AccountId != null) {
               addToMap((tsk.AccountId != null ? tsk.AccountId : tsk.WhatId), tsk, acctIdMap);
            }
            
            if (tsk.CallType == 'Inbound' && tsk.DS_Denali__DialSource_Action__c != null) {
               addToMap(tsk.DS_Denali__DialSource_Action__c, tsk, dsTaskMap);
            }
            
         } // if (String.isBlank(tsk.TimeZoneAbbrev__c
         
         
      } // for (Task tsk
      
      System.debug('checkRecords tasksToCheck='+tasksToCheck.size()+' leadIdMap='+leadIdMap.size()+' acctIdMap='+acctIdMap.size()+' ctctIdMap='+ctctIdMap.size()+' dsTaskMap='+dsTaskMap.size()+' areaCdMap='+areaCdMap.size());
      if (tasksToCheck.isEmpty()) {
         // we don't need to continue
         return;
      }
      
      checkLeads(leadIdMap);
      checkAccts(acctIdMap);
      checkCtcts(ctctIdMap);
      checkDialSource(dsTaskMap, areaCdMap);
      
      System.debug('checkRecords areaCdMap='+areaCdMap.size());
      checkAreaCode(areaCdMap);
   } // checkRecords
   
   public static void checkAreaCode(Map<String,Task[]> p_areaCdMap) {
      Map<String,Task[]> areaCdMap = checkIfProcessed(p_areaCdMap);
      if (!areaCdMap.isEmpty()) {
         AreaCode__c[] acs = [SELECT Id, Name, TimeZoneName__c, TimeZoneAbbrev__c FROM AreaCode__c WHERE NAME IN :areaCdMap.keySet()];
         for (AreaCode__c ac : acs) {
            checkTimeZone(areaCdMap.get(ac.Name), ac.TimeZoneAbbrev__c, 'AreaCode');
         } // for (AreaCode__c ac
      } // if (!areaCdMap.isEmpty
   } // checkAreaCode

   // add DialSource tasks to map by area code so we can perform that search   
   public static void checkDialSource(Map<String,Task[]> p_dsTaskMap, Map<String,Task[]> areaCdMap) {
      Map<String,Task[]> dsTaskMap = checkIfProcessed(p_dsTaskMap);
      if (!dsTaskMap.isEmpty()) {
         DS_Denali__DialSource_Action__c[] actions = [Select Id, InboundCallerId__c from DS_Denali__DialSource_Action__c where Id in :dsTaskMap.keySet() and InboundCallerId__c != null];
         for (DS_Denali__DialSource_Action__c action : actions) {
            Task[] tsks = dsTaskMap.get(action.Id);
            for (Task tsk : tsks) {
               addTaskByAreaCode(action.InboundCallerId__c, tsk, areaCdMap);
            }
         } // for (DS_Denali__DialSource_Action__c action
      } // if (!dsTaskMap.isEmpty
   } // checkDialSource
   
   public static void addTaskByAreaCode(String phoneNbr, Task tsk, Map<String, Task[]> areaCdMap) {
      // strip out the phone number
      String cleanPhone = Utilities.removeExtraChars(phoneNbr, Utilities.ALL_NUMBERS);
      System.debug('addTaskByAreaCode phoneNbr='+phoneNbr+' cleanPhone='+cleanPhone);
      if (String.isNotBlank(cleanPhone) && cleanPhone.length() >= 10) {
         // pull out the area code
         String areaCode = cleanPhone.left(3);
         Task[] tsks = (areaCdMap.containsKey(areaCode) ? areaCdMap.get(areaCode) : new Task[]{});
         tsks.add(tsk);
         areaCdMap.put(areaCode,tsks);
      }
   } // addTaskByAreaCode
   
   public static void checkCtcts(Map<String,Task[]> p_ctctIdMap) {
      // first check to see if the records were already handled (by the account)
      Map<String,Task[]> ctctIdMap = checkIfProcessed(p_ctctIdMap);
      if (!ctctIdMap.isEmpty()) {
         Contact[] ctcts = [Select Id, Name, Account.Name, Account.TimeZoneAbbrev__c from Contact where Id in :ctctIdMap.keySet() and Account.TimeZoneAbbrev__c != null];
         for (Contact ctct : ctcts) {
            checkTimeZone(ctctIdMap.get(ctct.Id), ctct.Account.TimeZoneAbbrev__c, ObjectHelper.OBJECT_CONTACT);
         } // for (Contact ctct
      } // if (!ctctIdMap
   } // checkCtcts
   
   // check through to see if there are any records that still don't have the TimeZoneAbbrev__c field populated
   public static Map<String,Task[]> checkIfProcessed(Map<String,Task[]> tskMap) {
      Map<String,Task[]> notProcessedMap = new Map<String,Task[]>();
      for (String keyId : tskMap.keySet()) {
         Task[] tsks = tskMap.get(keyId);
         Task[] tsksNotProcessed = new Task[]{};
         for (Task tsk : tsks) {
            if (String.isBlank(tsk.TimeZoneAbbrev__c)) {
               tsksNotProcessed.add(tsk);
            }
         } // for (Task tsk : tsks
         if (!tsksNotProcessed.isEmpty()) {
            notProcessedMap.put(keyId, tsksNotProcessed);
         }
      } // for (Id keyId
      return notProcessedMap;
   } // checkIfProcessed
   
   public static void checkAccts(Map<String,Task[]> acctIdMap) {
      if (!acctIdMap.isEmpty()) {
         Account[] accts = [Select Id, Name, TimeZoneAbbrev__c from Account where Id in :acctIdMap.keySet() and TimeZoneAbbrev__c != null];
         for (Account acct : accts) {
            checkTimeZone(acctIdMap.get(acct.Id), acct.TimeZoneAbbrev__c, ObjectHelper.OBJECT_ACCOUNT);
         } // for (Account acct
      } // if (!acctIdMap.isEmpty
   } // checkAccts
   
   public static void checkLeads(Map<String,Task[]> leadIdMap) {
      if (!leadIdMap.isEmpty()) {
         Lead[] leads = [Select Id, Name, TimeZoneAbbrev__c from Lead where Id in :leadIdMap.keySet() and TimeZoneAbbrev__c != null];
         for (Lead ld : leads) {
            checkTimeZone(leadIdMap.get(ld.Id), ld.TimeZoneAbbrev__c, ObjectHelper.OBJECT_LEAD);
         } // for (Lead ld
      } // if (!leadIdMap
   } // checkLeads
   
   public static void checkTimeZone(Task[] tsks, String timeZoneAbbrev, String objectName) {
      if (tsks != null) {
         for (Task tsk : tsks) {
            System.debug('checkTimeZone setting time zone of tsk '+tsk.Subject+' to '+timeZoneAbbrev+' from '+objectname);
            tsk.TimeZoneAbbrev__c = timeZoneAbbrev;
         }
      } // if (tsks != null
      
   } // checkTimeZone
   

   public static void addToMap(String keyId, Task tsk, Map<String,Task[]> tskMap) {
      Task[] tsks = (tskMap.containsKey(keyId) ? tskMap.get(keyId) : new Task[]{});
      tsks.add(tsk);
      tskMap.put(keyId,tsks);
   } // addToMap

} // class TimeZoneHelper