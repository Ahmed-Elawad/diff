/** Methods for working on the Account Address object

 * 
 * History
 * -------
   01/20/2023 Dan Carmen         Created
   12/05/2023 Dan Carmen         Fix updating account if address id is blank

 */
public without sharing class AccountAddressMethods implements TriggerInterfaceC {
   public static Boolean SKIP_TRIGGER=false;
    
   public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      System.debug('AccountAddressMethods.handleTrigger SKIP_TRIGGER='+SKIP_TRIGGER+' isBefore='+isBefore+' isAfter='+isAfter);
      if (!SKIP_TRIGGER) {
         if (isBefore) {
             handleAddressBefore((AccountAddress__c[])recs, (Map<Id,AccountAddress__c>)oldMap);
         } else if (isAfter) {
             handleAddressAfter((AccountAddress__c[])recs, (Map<Id,AccountAddress__c>)oldMap);
         }
      } // if (!SKIP_TRIGGER
   } // handleTrigger
    
   public static void handleAddressBefore(AccountAddress__c[] recs, Map<Id,AccountAddress__c> oldMap) {
      Map<String,AccountAddress__c[]> addrByCaidMap = new Map<String,AccountAddress__c[]>();
       
      for (AccountAddress__c addr : recs) {
         if (addr.StartDate__c == null) {
            addr.StartDate__c = Date.today();
         }
         if (String.isBlank(addr.Name)) {
            addr.Name = addr.CAID__c; 
         }
         addr.Address__PostalCode__s = EntRespHelper.formatPostal(addr.Address__PostalCode__s);
         if (addr.Account__c == null && addr.CAID__c != null) {
            AccountAddress__c[] caidAddrs = (addrByCaidMap.containsKey(addr.CAID__c) ? addrByCaidMap.get(addr.CAID__c) : new AccountAddress__c[]{});
            caidAddrs.add(addr);
            addrByCaidMap.put(addr.CAID__c, caidAddrs);
         }
      } // for (AccountAddress__c addr
       
      if (!addrByCaidMap.isEmpty()) {
         Account[] accts = [Select Id, Name, Paychex_CAID__c, Paychex_CEID__c from Account where Paychex_CAID__c in :addrByCaidMap.keySet()];
         for (Account acct : accts) {
            AccountAddress__c[] caidAddrs = addrByCaidMap.remove(acct.Paychex_CAID__c);
            if (caidAddrs != null) {
               for (AccountAddress__c addr : caidAddrs) {
                  addr.Account__c = acct.Id;
                  //addr.Name = acct.Name;
                  addr.Processed__c = true;
                  StringHelper.addToProcessNotes(addr,'Matched '+acct.Name+' to this address.');
               }
            } // if (caidAddrs != null
         } // for (Account acct
         for (AccountAddress__c[] caidAddrs : addrByCaidMap.values()) {
            for (AccountAddress__c addr : caidAddrs) {
               //addr.Name = addr.CAID__c;
               StringHelper.addToProcessNotes(addr,'Could not find a match for '+addr.CAID__c);
            }
         }
      } // if (!addrByCaidMap.isEmpty
   } // handleAddressBefore
    
   public static void handleAddressAfter(AccountAddress__c[] recs, Map<Id,AccountAddress__c> oldMap) {
      Id[] acctIds = new Id[]{};
      for (AccountAddress__c addr : recs) {
         if (addr.Account__c != null) {
            acctIds.add(addr.Account__c);
         }
      } // for (AccountAddress__c[] addr
      if (!acctIds.isEmpty()) {
         Map<Id,Account> acctMap = getAcctMap(acctIds);
         Map<Id,Account> acctUpdateMap = new Map<Id,Account>();
         AccountAddress__c[] updateAddrs = new AccountAddress__c[]{};
         for (AccountAddress__c addr : recs) {
            Account acct = (addr.Account__c != null ? acctMap.get(addr.Account__c) : null);
            if (acct != null) {
               Boolean acctUpdated = false;
               // create a new instance because we're in the after context of the trigger.
               AccountAddress__c updateAddr = new AccountAddress__c(Id=addr.Id, ProcessNotes__c=addr.ProcessNotes__c);
               Boolean matchedLegal = false;
               if (addr.EnterpriseAID__c == acct.EnterpriseAAID__c) {
                  matchedLegal = true;
                  acctUpdated = (checkAcctUpdate(addr,updateAddr,acct,EZOnboardingRegistration.ADDR_LEGAL
                                                ,'LegalAddress__Street__s', 'LegalAddress__City__s', 'LegalAddress__StateCode__s', 'LegalAddress__PostalCode__s', 'LegalAddress__CountryCode__s')
                                       || acctUpdated);
               }
               
               //if ((acct.EnterpriseBillingId__c == null && !matchedLegal) || addr.EnterpriseAID__c == acct.EnterpriseBillingId__c) {
               if (addr.EnterpriseAID__c == acct.EnterpriseBillingId__c) {
                  //if (acct.EnterpriseBillingId__c == null) {
                  //    acct.EnterpriseBillingId__c = addr.EnterpriseAID__c;
                  //    acctUpdated = true;
                  //}
                  acctUpdated = (checkAcctUpdate(addr,updateAddr,acct,EZOnboardingRegistration.ADDR_BILL
                                                ,'BillingStreet', 'BillingCity', 'BillingState', 'BillingPostalCode', 'BillingCountry') 
                                       || acctUpdated);
               }
               //if ((acct.EnterpriseShippingId__c == null && !matchedLegal) || addr.EnterpriseAID__c == acct.EnterpriseShippingId__c) {
               if (addr.EnterpriseAID__c == acct.EnterpriseShippingId__c) {
                  //if (acct.EnterpriseShippingId__c == null) {
                  //    acct.EnterpriseShippingId__c = addr.EnterpriseAID__c;
                  //    acctUpdated = true;
                  //}
                  acctUpdated = (checkAcctUpdate(addr,updateAddr,acct,EZOnboardingRegistration.ADDR_SHIP
                                                ,'ShippingStreet', 'ShippingCity', 'ShippingState', 'ShippingPostalCode', 'ShippingCountry') 
                                       || acctUpdated);
               }
               if (acctUpdated) {
                  acctUpdateMap.put(acct.Id, acct);
                  updateAddrs.add(updateAddr);
               }
            } // if (acct != null
         } // for (AccountAddress__c addr
          
         ZipCheckOwner.SKIP_TRIGGERS=true;
         SKIP_TRIGGER=true;
         DmlHelper.performDML2(acctUpdateMap.values(), DmlHelper.DML_UPDATE, 'AccountAddressMethods', 'handleAddressAfter', 'Update Account Address', true); 
         DmlHelper.performDML2(updateAddrs, DmlHelper.DML_UPDATE, 'AccountAddressMethods', 'handleAddressAfter', 'Update AccountAddress__c object', true); 

      } // if (!acctIds.isEmpty
   } // handleAddressAfter
    
    public static Map<Id,Account> getAcctMap(Id[] acctIds) {
         Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Name, EnterpriseAAID__c, EnterpriseBillingId__c, EnterpriseShippingId__c
                                                              ,ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry
                                                              ,BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
                                                              ,LegalAddress__Street__s, LegalAddress__City__s, LegalAddress__StateCode__s
                                                              ,LegalAddress__PostalCode__s, LegalAddress__CountryCode__s
                                                              ,EBSBillToSiteID__c, OSSBillToSiteID__c, EBSShipToSiteID__c, OSSShipToSiteID__c
                                                          From Account
                                                         Where Id in :acctIds]);
       System.debug('getAcctMap acctIds='+acctIds.size()+' acctMap='+acctMap.size());
       return acctMap;
    } // getAcctMap
    
   public static boolean checkAcctUpdate(AccountAddress__c addr, AccountAddress__c updateAddr, Account acct, String addrType
                                        ,String street, String city, String state, String postal, String country) {
      Boolean acctUpdated = false;
      acctUpdated = (EZOnboardingRegistration.checkFieldChange(acct, acct, street, addr.Address__Street__s) || acctUpdated);
      acctUpdated = (EZOnboardingRegistration.checkFieldChange(acct, acct, city, addr.Address__City__s) || acctUpdated);
      acctUpdated = (EZOnboardingRegistration.checkFieldChange(acct, acct, state, addr.Address__StateCode__s) || acctUpdated);
      acctUpdated = (EZOnboardingRegistration.checkFieldChange(acct, acct, postal, addr.Address__PostalCode__s) || acctUpdated);
      acctUpdated = (EZOnboardingRegistration.checkFieldChange(acct, acct, country, addr.Address__CountryCode__s) || acctUpdated);
      if (acctUpdated) {
         StringHelper.addToProcessNotes(updateAddr,'Updated '+addrType+' on '+acct.Name);
      }
      /*
      if ((String.isNotBlank(addr.Address__Street__s) && addr.Address__Street__s != (String)acct.get(street))
          || (String.isNotBlank(addr.Address__City__s) && addr.Address__City__s != (String)acct.get(city))
          || (String.isNotBlank(addr.Address__StateCode__s) && addr.Address__StateCode__s != (String)acct.get(state))
          || (String.isNotBlank(addr.Address__PostalCode__s) && addr.Address__PostalCode__s != (String)acct.get(postal))
          || (String.isNotBlank(addr.Address__CountryCode__s) && addr.Address__CountryCode__s != (String)acct.get(country))) {
         acctUpdated = true;
         acct.put(street,addr.Address__Street__s);
         acct.put(city,addr.Address__City__s);
         acct.put(state,addr.Address__StateCode__s);
         acct.put(postal,addr.Address__PostalCode__s);
         acct.put(country,addr.Address__CountryCode__s);
         StringHelper.addToProcessNotes(updateAddr,'Updated '+addrType+' on '+acct.Name);
      }
      */
      if (addrType == EZOnboardingRegistration.ADDR_BILL && String.isNotBlank(addr.EBSBillToSiteID__c) && String.isNotBlank(addr.OSSBillToSiteID__c)
          && (addr.EBSBillToSiteID__c != acct.EBSBillToSiteID__c || addr.OSSBillToSiteID__c != acct.OSSBillToSiteID__c)) {
         acctUpdated = true;
         acct.EBSBillToSiteID__c = addr.EBSBillToSiteID__c;
         acct.OSSBillToSiteID__c = addr.OSSBillToSiteID__c;
      }
                                            
      if (addrType == EZOnboardingRegistration.ADDR_SHIP && String.isNotBlank(addr.EBSShipToSiteID__c) && String.isNotBlank(addr.OSSShipToSiteID__c)
          && (addr.EBSShipToSiteID__c != acct.EBSShipToSiteID__c || addr.OSSShipToSiteID__c != acct.OSSShipToSiteID__c)) {
         acctUpdated = true;
         acct.EBSShipToSiteID__c = addr.EBSShipToSiteID__c;
         acct.OSSShipToSiteID__c = addr.OSSShipToSiteID__c;
      }
      return acctUpdated;
   } // checkAcctUpdate
    
} // class AccountAddressMethods