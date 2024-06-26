/** Test methods for the AccountAddressMethods class

 * 
 * History
 * -------
   01/20/2023 Dan Carmen         Created
   12/05/2023 Dan Carmen         Fix updating account if address id is blank

 */
@isTest
public class AccountAddressMethodsTest {
    static testMethod void testFindAccount() {
       Account acct1 = new Account(Name='Account1', Paychex_CAID__c='CAID1234');
       Account acct2 = new Account(Name='Account2', Paychex_CAID__c='CAID2345');
       Account acct3 = new Account(Name='Account3', Paychex_CAID__c='CAID3456');
       Account acct5 = new Account(Name='Account5', Paychex_CAID__c='CAID3458',EnterpriseAAID__c='2234511110', EnterpriseBillingId__c='2234511111', EnterpriseShippingId__c='2234511112');
       Account acct6 = new Account(Name='Account6', Paychex_CAID__c='CAID3459',EnterpriseAAID__c='2234511116', EnterpriseBillingId__c='2234511117', EnterpriseShippingId__c='2234511118'
                                    ,BillingStreet='343 Main St', BillingCity='Rachacha', BillingState='NY', BillingPostalCode='14624',BillingCountry='US'
                                    ,ShippingStreet='345 Main St', ShippingCity='Rachacha', ShippingState='NY', ShippingPostalCode='14624');
       Account acct7 = new Account(Name='Account7', Paychex_CAID__c='CAID3460',EnterpriseAAID__c='2234511120', EnterpriseBillingId__c='2234511120', EnterpriseShippingId__c='2234511120');
       ZipCheckOwner.SKIP_TRIGGERS=true;
       insert new Account[]{acct1,acct2,acct3,acct5,acct6,acct7};
       
       AccountAddress__c addr1a = new AccountAddress__c(Name='Addr1a', EnterpriseAID__c='1234511111', CAID__c=acct1.Paychex_CAID__c, Address__PostalCode__s='14624'
                                                        ,EBSBillToSiteID__c='444123456', OSSBillToSiteID__c='444123457'
                                                        ,EBSShipToSiteID__c='444123458', OSSShipToSiteID__c='444123459');
       AccountAddress__c addr1b = new AccountAddress__c(Name='Addr1b', EnterpriseAID__c='1234511112', CAID__c=acct1.Paychex_CAID__c, Address__PostalCode__s='14626');
       AccountAddress__c addr2a = new AccountAddress__c(Name='Addr2a', EnterpriseAID__c='1234511113', CAID__c=acct2.Paychex_CAID__c, Address__PostalCode__s='14624');
       // see if this stays linked to acct3 even though the caid is acct2
       AccountAddress__c addr3a = new AccountAddress__c(Name='Addr3a', EnterpriseAID__c='1234511114', Account__c=acct3.Id, CAID__c=acct2.Paychex_CAID__c, Address__PostalCode__s='14624');
       AccountAddress__c addr3b = new AccountAddress__c(Name='Addr3b', EnterpriseAID__c='1234511115', CAID__c=acct3.Paychex_CAID__c, Address__PostalCode__s='14626');
       AccountAddress__c addr4a = new AccountAddress__c(EnterpriseAID__c='1234511116', CAID__c='NotACaid', Address__PostalCode__s='14626');

       AccountAddress__c addr5a = new AccountAddress__c(Name='Addr5a', EnterpriseAID__c='2234511110', CAID__c=acct5.Paychex_CAID__c
                                                        ,Address__Street__s='123 Main St', Address__City__s='Somecity', Address__StateCode__s='NY'
                                                        , Address__PostalCode__s='14626', Address__CountryCode__s='US');
       AccountAddress__c addr5b = new AccountAddress__c(Name='Addr5b', EnterpriseAID__c='2234511111', CAID__c=acct5.Paychex_CAID__c
                                                        ,Address__Street__s='234 South Ave', Address__City__s='Somecity', Address__StateCode__s='NY'
                                                        , Address__PostalCode__s='14627', Address__CountryCode__s='US');
       AccountAddress__c addr6a = new AccountAddress__c(Name='Addr6a', EnterpriseAID__c='2234511117', CAID__c=acct6.Paychex_CAID__c
                                                        ,Address__Street__s='343 Main St', Address__City__s='Rachacha', Address__StateCode__s='NY'
                                                        , Address__PostalCode__s='14624', Address__CountryCode__s='US');
       AccountAddress__c addr6b = new AccountAddress__c(Name='Addr6b', EnterpriseAID__c='2234511118', CAID__c=acct6.Paychex_CAID__c
                                                        ,Address__Street__s='345 Main St', Address__City__s='Rachacha', Address__StateCode__s='NY'
                                                        , Address__PostalCode__s='14624-1234', Address__CountryCode__s='US');
       AccountAddress__c addr7a = new AccountAddress__c(Name='Addr7a', EnterpriseAID__c='2234511120', CAID__c=acct7.Paychex_CAID__c
                                                        ,Address__Street__s='347 Main St', Address__City__s='Rachacha', Address__StateCode__s='NY'
                                                        , Address__PostalCode__s='14624', Address__CountryCode__s='US');
       
       insert new AccountAddress__c[]{addr1a,addr1b,addr2a,addr3a,addr3b,addr4a, addr5a, addr5b, addr6a, addr6b, addr7a};
       
       Map<Id,AccountAddress__c> addrMap = new Map<Id,AccountAddress__c>([Select Id, Name, Account__c
                                                                                ,Address__Street__s, Address__City__s
                                                                                ,Address__StateCode__s, Address__PostalCode__s, Address__CountryCode__s
                                                                                ,StartDate__c, ProcessNotes__c
                                                                                 From AccountAddress__c]);
       Assert.areEqual(acct1.Id, addrMap.get(addr1a.Id).Account__c);
       //Assert.areEqual(acct1.Name, addrMap.get(addr1a.Id).Name);

       Assert.areEqual(acct1.Id, addrMap.get(addr1b.Id).Account__c);
       //Assert.areEqual(acct1.Name, addrMap.get(addr1b.Id).Name);

       Assert.areEqual(acct2.Id, addrMap.get(addr2a.Id).Account__c);
       //Assert.areEqual(acct2.Name, addrMap.get(addr2a.Id).Name);

       Assert.areEqual(acct3.Id, addrMap.get(addr3a.Id).Account__c);
       Assert.areEqual('Addr3a', addrMap.get(addr3a.Id).Name);

       Assert.areEqual(acct3.Id, addrMap.get(addr3b.Id).Account__c);
       //Assert.areEqual(acct3.Name, addrMap.get(addr3b.Id).Name);

       Assert.areEqual(null, addrMap.get(addr4a.Id).Account__c);
       Assert.areEqual('NotACaid', addrMap.get(addr4a.Id).Name);
        
       Map<Id,Account> acctMap = AccountAddressMethods.getAcctMap(new Id[]{acct1.Id, acct5.Id,acct6.Id,acct7.Id});
       Account checkAcct1 = acctMap.get(acct1.Id);
       Assert.isNull(checkAcct1.EnterpriseBillingId__c);
       Assert.isNull(checkAcct1.EnterpriseShippingId__c);
       //Assert.areEqual(addr1a.EnterpriseAID__c, checkAcct1.EnterpriseBillingId__c);
       //Assert.areEqual(addr1a.Address__PostalCode__s, checkAcct1.BillingPostalCode);
       //Assert.areEqual(addr1a.EBSBillToSiteID__c, checkAcct1.EBSBillToSiteID__c);
       //Assert.areEqual(addr1a.OSSBillToSiteID__c, checkAcct1.OSSBillToSiteID__c);
       //Assert.areEqual(addr1a.EnterpriseAID__c, checkAcct1.EnterpriseShippingId__c);
       //Assert.areEqual(addr1a.Address__PostalCode__s, checkAcct1.ShippingPostalCode);
       //Assert.areEqual(addr1a.EBSShipToSiteID__c, checkAcct1.EBSShipToSiteID__c);
       //Assert.areEqual(addr1a.OSSShipToSiteID__c, checkAcct1.OSSShipToSiteID__c);
        
       Account checkAcct5 = acctMap.get(acct5.Id);
       Assert.areEqual(addr5a.Address__Street__s, checkAcct5.LegalAddress__Street__s);
       Assert.areEqual(addr5a.Address__City__s, checkAcct5.LegalAddress__City__s);
       Assert.areEqual(addr5a.Address__StateCode__s, checkAcct5.LegalAddress__StateCode__s);
       Assert.areEqual(addr5a.Address__PostalCode__s, checkAcct5.LegalAddress__PostalCode__s);
       Assert.areEqual(addr5a.Address__CountryCode__s, checkAcct5.LegalAddress__CountryCode__s);

       Assert.areEqual(addr5b.Address__Street__s, checkAcct5.BillingStreet);
       Assert.areEqual(addr5b.Address__City__s, checkAcct5.BillingCity);
       Assert.areEqual(addr5b.Address__StateCode__s, checkAcct5.BillingState);
       Assert.areEqual(addr5b.Address__PostalCode__s, checkAcct5.BillingPostalCode);
       Assert.areEqual(addr5b.Address__CountryCode__s, checkAcct5.BillingCountry);

       Assert.isNull(checkAcct5.ShippingStreet);
       Assert.isNull(checkAcct5.ShippingCity);
       Assert.isNull(checkAcct5.ShippingState);
       Assert.isNull(checkAcct5.ShippingPostalCode);
       Assert.isNull(checkAcct5.ShippingCountry);
       addr5a = addrMap.get(addr5a.Id);
       Assert.isTrue(addr5a.ProcessNotes__c.contains('Updated '+EZOnboardingRegistration.ADDR_LEGAL));

       addr5b = addrMap.get(addr5b.Id);
       Assert.isTrue(addr5b.ProcessNotes__c.contains('Updated '+EZOnboardingRegistration.ADDR_BILL));

       Account checkAcct6 = acctMap.get(acct6.Id);
       Assert.isNull(checkAcct6.LegalAddress__Street__s);
       Assert.isNull(checkAcct6.LegalAddress__City__s);
       Assert.isNull(checkAcct6.LegalAddress__StateCode__s);
       Assert.isNull(checkAcct6.LegalAddress__PostalCode__s);
       Assert.areEqual('US', checkAcct6.LegalAddress__CountryCode__s);

       Assert.areEqual(addr6a.Address__Street__s, checkAcct6.BillingStreet);
       Assert.areEqual(addr6a.Address__City__s, checkAcct6.BillingCity);
       Assert.areEqual(addr6a.Address__StateCode__s, checkAcct6.BillingState);
       Assert.areEqual(addr6a.Address__PostalCode__s, checkAcct6.BillingPostalCode);
       Assert.areEqual(addr6a.Address__CountryCode__s, checkAcct6.BillingCountry);

       Assert.areEqual(addr6b.Address__Street__s, checkAcct6.ShippingStreet);
       Assert.areEqual(addr6b.Address__City__s, checkAcct6.ShippingCity);
       Assert.areEqual(addr6b.Address__StateCode__s, checkAcct6.ShippingState);
       Assert.areEqual(addr6b.Address__PostalCode__s, checkAcct6.ShippingPostalCode);
       Assert.areEqual(addr6b.Address__CountryCode__s, checkAcct6.ShippingCountry);
        
       addr6a = addrMap.get(addr6a.Id);
       Assert.isFalse(addr6a.ProcessNotes__c.contains('Updated'),addr6a.ProcessNotes__c);

       addr6b = addrMap.get(addr6b.Id);
       Assert.isTrue(addr6b.ProcessNotes__c.contains('Updated '+EZOnboardingRegistration.ADDR_SHIP),addr6b.ProcessNotes__c);

       Account checkAcct7 = acctMap.get(acct7.Id);
       Assert.areEqual(addr7a.Address__Street__s, checkAcct7.LegalAddress__Street__s);
       Assert.areEqual(addr7a.Address__City__s, checkAcct7.LegalAddress__City__s);
       Assert.areEqual(addr7a.Address__StateCode__s, checkAcct7.LegalAddress__StateCode__s);
       Assert.areEqual(addr7a.Address__PostalCode__s, checkAcct7.LegalAddress__PostalCode__s);
       Assert.areEqual(addr7a.Address__CountryCode__s, checkAcct7.LegalAddress__CountryCode__s);

       Assert.areEqual(addr7a.Address__Street__s, checkAcct7.BillingStreet);
       Assert.areEqual(addr7a.Address__City__s, checkAcct7.BillingCity);
       Assert.areEqual(addr7a.Address__StateCode__s, checkAcct7.BillingState);
       Assert.areEqual(addr7a.Address__PostalCode__s, checkAcct7.BillingPostalCode);
       Assert.areEqual(addr7a.Address__CountryCode__s, checkAcct7.BillingCountry);

       Assert.areEqual(addr7a.Address__Street__s, checkAcct7.ShippingStreet);
       Assert.areEqual(addr7a.Address__City__s, checkAcct7.ShippingCity);
       Assert.areEqual(addr7a.Address__StateCode__s, checkAcct7.ShippingState);
       Assert.areEqual(addr7a.Address__PostalCode__s, checkAcct7.ShippingPostalCode);
       Assert.areEqual(addr7a.Address__CountryCode__s, checkAcct7.ShippingCountry);
        
       addr7a = addrMap.get(addr7a.Id);
       Assert.isTrue(addr7a.ProcessNotes__c.contains('Updated '+EZOnboardingRegistration.ADDR_SHIP),addr7a.ProcessNotes__c);
       Assert.isTrue(addr7a.ProcessNotes__c.contains('Updated '+EZOnboardingRegistration.ADDR_BILL),addr7a.ProcessNotes__c);
       Assert.isTrue(addr7a.ProcessNotes__c.contains('Updated '+EZOnboardingRegistration.ADDR_LEGAL),addr7a.ProcessNotes__c);

    } // testFindAccount
    
} // class AccountAddressMethodsTest