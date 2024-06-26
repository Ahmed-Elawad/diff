/* 
 * Test methods for the TimeZoneHelper class
 *
 * History
 * -------
   01/11/2019 Dan Carmen       Created
   11/14/2019 Dan Carmen       Remove ISDC fields
   06/18/2021 Dan Carmen       Add Referral Accounts
   09/22/2021 Carrie Marciano  Added ,DS_Denali__Owner__c=UserInfo.getUserId() and 	,DS_Denali__Inbound_DNIS__c='InboundCall' back into the creation of DialSource Action records
   03/22/2023 Dan Carmen       Added address verifications
   05/24/2023 Dan Carmen       Verify State Code before setting legal state
   06/12/2023 Dan Carmen       Make sure picklist value is active in state codes
   07/13/2023 Dan Carmen       Add logic to handle non-US states/provinces
   10/13/2023 Dan Carmen       Remove double spaces from street addresses
   02/07/2024 Dan Carmen       Additional checks to make sure address is filled in, added Contact
   04/30/2024 Dan Carmen       Add additional testing


 */
@isTest
private class TimeZoneHelperTest {

   @testSetup
   public static void setup(){
      TriggerMethodsTest.createTriggerSetting('TaskBefore', true, false, false, false,new String[]{'TimeZoneHelper'});
      TriggerMethodsTest.createTriggerSetting('ReferralAccountBefore', true, false, false, false,new String[]{'TimeZoneHelper'});
      TriggerMethodsTest.createTriggerSetting('LeadBefore', true, false, false, false,new String[]{'TimeZoneHelper'});
      TriggerMethodsTest.createTriggerSetting('AccountBefore', true, false, false, false,new String[]{'TimeZoneHelper'});
      TriggerMethodsTest.createTriggerSetting('ContactBefore', true, false, false, false,new String[]{'TimeZoneHelper'});
      TriggerMethodsTest.createTriggerSetting('UserBefore', true, false, false, false,new String[]{'TimeZoneHelper'});
      TriggerMethodsTest.saveSetupClasses();
   } // setup

   static testMethod void testTaskTimeZones() {
      Account acct1 = new Account(Name='Account1', TimeZoneAbbrev__c='ET');
      Account acct2 = new Account(Name='Account2', TimeZoneAbbrev__c='MT');
      Account[] accts = new Account[]{acct1,acct2};
      insert accts;
      
      Contact ctct2 = new Contact(AccountId=acct2.Id, LastName='Contact2');
      insert ctct2;
      
      Lead ld1 = new Lead(LastName='LeadLast1', Company='LeadCompany1', TimeZoneAbbrev__c='PT');
      Lead ld2 = new Lead(LastName='LeadLast2', Company='LeadCompany2');
      Lead[] lds = new Lead[]{ld1,ld2};
      insert lds;
      
      AreaCode__c ac1 = new AreaCode__c(Name='512',State__c='TX',TimeZoneAbbrev__c='CT',TimeZoneName__c='America/Chicago');
      AreaCode__c ac2 = new AreaCode__c(Name='541',State__c='OR',TimeZoneAbbrev__c='PT',TimeZoneName__c='America/Los_Angeles');
      AreaCode__c ac3 = new AreaCode__c(Name='561',State__c='FL',TimeZoneAbbrev__c='ET',TimeZoneName__c='America/New_York');
      AreaCode__c[] areaCodes = new AreaCode__c[]{ac1,ac2,ac3};
      insert areaCodes;
      
      Schema.RecordTypeInfo rtInbound = CallCenterHelper.getInboundRt();

      DS_Denali__DialSource_Sessions_V3__c dsSession = new DS_Denali__DialSource_Sessions_V3__c(Name='Test Session',DS_Denali__Session_Date__c=Datetime.now());
      insert dsSession;
      
      String phone1 = '(512) 555-1234';
      String phone2 = '(541) 555-2345';
      
      DS_Denali__DialSource_Action__c action1 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtInbound.getRecordTypeId()
                                                       ,DS_Denali__Owner__c=UserInfo.getUserId()
                                                       ,DS_Denali__Call_Campaign__c='Call Campaign1'
                                                       ,DS_Denali__Phone__c=phone1
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id
                                                       ,DS_Denali__Inbound_DNIS__c='InboundCall'                             
                                                       ,DS_Denali__Inbound_DNIS_Name__c='DNIS Name1'
                                                       ,InboundCallerId__c=phone1);
      DS_Denali__DialSource_Action__c action2 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtInbound.getRecordTypeId()
                                                       ,DS_Denali__Owner__c=UserInfo.getUserId()
                                                       ,DS_Denali__Call_Campaign__c='Call Campaign1'
                                                       ,DS_Denali__Phone__c=phone2
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id
                                                       ,DS_Denali__Inbound_DNIS__c='InboundCall'                             
                                                       ,DS_Denali__Inbound_DNIS_Name__c='DNIS Name2'
                                                       ,InboundCallerId__c=phone2);
      DS_Denali__DialSource_Action__c[] actions = new DS_Denali__DialSource_Action__c[]{action1,action2};
      insert actions;

      Task tsk1 = new Task(Subject='tsk1', ActivityDate=Date.today(), WhatId=acct1.Id);
      Task tsk2 = new Task(Subject='tsk2', ActivityDate=Date.today(), WhoId=ctct2.Id);
      Task tsk3 = new Task(Subject='tsk3', ActivityDate=Date.today(), WhoId=ld1.Id);
      Task tsk4 = new Task(Subject='tsk4', ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=action1.Id);
      Task tsk5 = new Task(Subject='tsk5', ActivityDate=Date.today(), DS_Denali__DialSource_Action__c=action2.Id);
      // tasks with no caller id
      Task tsk6 = new Task(Subject='tsk6', ActivityDate=Date.today(), WhoId=ld2.Id);
      Task tsk7 = new Task(Subject='tsk7', ActivityDate=Date.today());
      Task[] tsks = new Task[]{tsk1,tsk2,tsk3,tsk4,tsk5,tsk6,tsk7};
          
      Test.startTest();
      insert tsks;
      Test.stopTest();
      
      Map<Id,Task> taskMap = new Map<Id,Task>([Select Id, Subject, TimeZoneAbbrev__c from Task where Id in :tsks]);
      tsk1 = taskMap.get(tsk1.Id);
      Assert.areEqual(acct1.TimeZoneAbbrev__c,tsk1.TimeZoneAbbrev__c);
      
      tsk2 = taskMap.get(tsk2.Id);
      Assert.areEqual(acct2.TimeZoneAbbrev__c,tsk2.TimeZoneAbbrev__c);

      tsk3 = taskMap.get(tsk3.Id);
      Assert.areEqual(ld1.TimeZoneAbbrev__c,tsk3.TimeZoneAbbrev__c);
      
      tsk4 = taskMap.get(tsk4.Id);
      Assert.areEqual(ac1.TimeZoneAbbrev__c,tsk4.TimeZoneAbbrev__c);
      
      tsk5 = taskMap.get(tsk5.Id);
      Assert.areEqual(ac2.TimeZoneAbbrev__c,tsk5.TimeZoneAbbrev__c);
      
      tsk6 = taskMap.get(tsk6.Id);
      Assert.isNull(tsk6.TimeZoneAbbrev__c);
      
      tsk7 = taskMap.get(tsk7.Id);
      Assert.isNull(tsk7.TimeZoneAbbrev__c);
      

        
   } // testTaskTimeZones
   
   static testMethod void testRefAccts() {
      TimeZoneHelper.CLEAR_INVALID_STATE=true;
      TimeZoneHelper.ALWAYS_SET_CITY_STATE=true;

      Zip_Code_Information__c zci1 = new Zip_Code_Information__c(Name='14624',TimeZoneAbbrev__c='ET',City__c='Rochester', State__c='NY');
      Zip_Code_Information__c zci2 = new Zip_Code_Information__c(Name='37205',TimeZoneAbbrev__c='CT',City__c='Nashville', State__c='TN');
      Zip_Code_Information__c zci3 = new Zip_Code_Information__c(Name='90210',TimeZoneAbbrev__c='PT',City__c='Beverly Hills', State__c='CA');
      Zip_Code_Information__c[] zcis = new Zip_Code_Information__c[]{zci1,zci2,zci3};
      insert zcis;
      
      Referral_Account__c refAcct1 = new Referral_Account__c(Name='RefAcct1', Street_Address_1__c='123 Main St', Street_Address_2__c='Apt 1', City__c='Rachacha', State_Province__c='NN', Zip_Postal_Code__c=zci1.Name);
      Referral_Account__c refAcct2 = new Referral_Account__c(Name='RefAcct2', Street_Address_1__c='123 Main St', City__c='Rochester', State_Province__c='NN', Zip_Postal_Code__c=zci2.Name);
      Referral_Account__c refAcct3 = new Referral_Account__c(Name='RefAcct3', Street_Address_1__c='123 Main St', City__c='Rachacha', State_Province__c='NY', Zip_Postal_Code__c=zci3.Name);
      Referral_Account__c refAcct4 = new Referral_Account__c(Name='RefAcct4', Street_Address_1__c='123 Main St', Street_Address_2__c='Apt 1', City__c=null, State_Province__c=null, Zip_Postal_Code__c='12345');
      Referral_Account__c[] refAccts = new Referral_Account__c[]{refAcct1,refAcct2,refAcct3,refAcct4};
      insert refAccts;
       
      Map<Id,Referral_Account__c> refAcctMap = new Map<Id,Referral_Account__c>([Select Id, Name
                                                                                      ,Street_Address_1__c,Street_Address_2__c, City__c, State_Province__c
                                                                                      ,Zip_Postal_Code__c, TimeZoneAbbrev__c 
                                                                                      ,Address__Street__s, Address__City__s, Address__StateCode__s
                                                                                      ,Address__PostalCode__s, Address__CountryCode__s
                                                                                  from Referral_Account__c]);
      refAcct1 = refAcctMap.get(refAcct1.Id);
      Assert.areEqual(zci1.TimeZoneAbbrev__c, refAcct1.TimeZoneAbbrev__c);
      Assert.areEqual(zci1.City__c, refAcct1.City__c);
      Assert.areEqual(zci1.City__c, refAcct1.Address__City__s);
      Assert.areEqual(refAcct1.Street_Address_1__c+'\n'+refAcct1.Street_Address_2__c, refAcct1.Address__Street__s);
      Assert.areEqual(zci1.State__c, refAcct1.State_Province__c);
      Assert.areEqual(zci1.State__c, refAcct1.Address__StateCode__s);
      Assert.areEqual(refAcct1.Zip_Postal_Code__c, refAcct1.Address__PostalCode__s);
      Assert.areEqual('US', refAcct1.Address__CountryCode__s);
       
      refAcct2 = refAcctMap.get(refAcct2.Id);
      Assert.areEqual(zci2.TimeZoneAbbrev__c, refAcct2.TimeZoneAbbrev__c);
      Assert.areEqual(zci2.City__c, refAcct2.City__c);
      Assert.areEqual(zci2.City__c, refAcct2.Address__City__s);
      Assert.areEqual(refAcct2.Street_Address_1__c, refAcct2.Address__Street__s);
      Assert.areEqual(zci2.State__c, refAcct2.State_Province__c);
      Assert.areEqual(zci2.State__c, refAcct2.Address__StateCode__s);
      Assert.areEqual(refAcct2.Zip_Postal_Code__c, refAcct2.Address__PostalCode__s);
      Assert.areEqual('US', refAcct2.Address__CountryCode__s);

      Assert.areEqual(zci3.TimeZoneAbbrev__c, refAcctMap.get(refAcct3.Id).TimeZoneAbbrev__c);
      refAcct3 = refAcctMap.get(refAcct3.Id);
      Assert.areEqual(zci3.TimeZoneAbbrev__c, refAcct3.TimeZoneAbbrev__c);
      Assert.areEqual(zci3.City__c, refAcct3.City__c);
      Assert.areEqual(zci3.City__c, refAcct3.Address__City__s);
      Assert.areEqual(refAcct3.Street_Address_1__c, refAcct3.Address__Street__s);
      Assert.areEqual(zci3.State__c, refAcct3.State_Province__c);
      Assert.areEqual(zci3.State__c, refAcct3.Address__StateCode__s);
      Assert.areEqual(refAcct3.Zip_Postal_Code__c, refAcct3.Address__PostalCode__s);
      Assert.areEqual('US', refAcct3.Address__CountryCode__s);

      refAcct4 = refAcctMap.get(refAcct4.Id);
      Assert.isNull(refAcctMap.get(refAcct4.Id).TimeZoneAbbrev__c);
      Assert.isNull(refAcct4.City__c);
      Assert.isNull(refAcct4.Address__City__s);
      Assert.areEqual(refAcct4.Street_Address_1__c+'\n'+refAcct4.Street_Address_2__c, refAcct4.Address__Street__s);
      Assert.isNull(refAcct4.State_Province__c);
      Assert.isNull(refAcct4.Address__StateCode__s);
      Assert.areEqual(refAcct4.Zip_Postal_Code__c, refAcct4.Address__PostalCode__s);
      Assert.areEqual('US', refAcct4.Address__CountryCode__s);

      refAcct4.Zip_Postal_Code__c = zci1.Name;
      TriggerMethods.clearVariables();
      update refAcct4;
       
      refAcct4 = [Select Id, Name
                        ,Street_Address_1__c,Street_Address_2__c, City__c, State_Province__c
                        ,Zip_Postal_Code__c, TimeZoneAbbrev__c 
                        ,Address__Street__s, Address__City__s, Address__StateCode__s
                        ,Address__PostalCode__s, Address__CountryCode__s
                    from Referral_Account__c where Id=:refAcct4.Id];
      Assert.areEqual(zci1.TimeZoneAbbrev__c, refAcct4.TimeZoneAbbrev__c);
      Assert.areEqual(zci1.City__c, refAcct4.City__c);
      Assert.areEqual(zci1.City__c, refAcct4.Address__City__s);
      Assert.areEqual(refAcct4.Street_Address_1__c+'\n'+refAcct4.Street_Address_2__c, refAcct4.Address__Street__s);
      Assert.areEqual(zci1.State__c, refAcct4.State_Province__c);
      Assert.areEqual(zci1.State__c, refAcct4.Address__StateCode__s);
      Assert.areEqual(refAcct4.Zip_Postal_Code__c, refAcct4.Address__PostalCode__s);
      Assert.areEqual('US', refAcct4.Address__CountryCode__s);
   } // testRefAccts
    
    static testMethod void testTimeZone() {
      ZipCodeInformationTest.setupZips();
      Lead ld1 = new Lead(Company='Test Lead1', LastName='LeadLast1', PostalCode=ZipCodeInformationTest.zci1.Name);
      Lead ld2 = new Lead(Company='Test Lead2', LastName='LeadLast2', PostalCode=ZipCodeInformationTest.zci1.Name, Phone=ZipCodeInformationTest.zci1.AreaCode__c+' 111-2222');
      Lead ld3 = new Lead(Company='Test Lead3', LastName='LeadLast3', Phone=ZipCodeInformationTest.zci1.AreaCode__c+' 111-2222');
      Lead ld4 = new Lead(Company='Test Lead4', LastName='LeadLast4', PostalCode='99999');
      Lead[] leads = new Lead[]{ld1,ld2,ld3,ld4};
      insert leads;

      Map<Id,Lead> leadMap = new Map<Id,Lead>([Select Id, Name, TimeZoneAbbrev__c, TimeZoneName__c from Lead where Id in :leads]);
      Lead checkLd1 = leadMap.get(ld1.Id);
      Assert.areEqual(ZipCodeInformationTest.zci1.TimeZoneName__c, checkLd1.TimeZoneName__c);
      Assert.areEqual(ZipCodeInformationTest.zci1.TimeZoneAbbrev__c, checkLd1.TimeZoneAbbrev__c);

      Lead checkLd2 = leadMap.get(ld2.Id);
      Assert.areEqual(ZipCodeInformationTest.zci1.TimeZoneName__c, checkLd2.TimeZoneName__c);
      Assert.areEqual(ZipCodeInformationTest.zci1.TimeZoneAbbrev__c, checkLd2.TimeZoneAbbrev__c);

      Lead checkLd3 = leadMap.get(ld3.Id);
      Assert.areEqual(ZipCodeInformationTest.zci1.TimeZoneName__c, checkLd3.TimeZoneName__c);
      Assert.areEqual(ZipCodeInformationTest.zci1.TimeZoneAbbrev__c, checkLd3.TimeZoneAbbrev__c);

      Lead checkLd4 = leadMap.get(ld4.Id);
      Assert.isNull(checkLd4.TimeZoneName__c);
      Assert.isNull(checkLd4.TimeZoneAbbrev__c);

    } // testTimeZone
    
    static testMethod void testAcctAddressInfo() {
       TimeZoneHelper.CLEAR_INVALID_STATE=false;
       TimeZoneHelper.ALWAYS_SET_CITY_STATE=false;
       Account acct1 = new Account(Name='Account1', ShippingState='New York', BillingState='Vermont', Legal_State__c='Not A State', Legal_Street__c='123 Main Street', Legal_City__c='Rochester', Legal_Postal_Code__c='14624');
       Account acct2 = new Account(Name='Account2', ShippingState='NY', BillingState='Not A State', Legal_State__c='New York', Legal_Street__c=null, Legal_City__c='Rochester', Legal_Postal_Code__c='14624');
       Account acct3 = new Account(Name='Account3', ShippingState='NY', BillingState='NY', ShippingStreet='123 Main St', BillingStreet='123 Main St', ShippingPostalCode='14624', BillingPostalCode='14624');
       Account acct4 = new Account(Name='Account4', ShippingState='NY', BillingState='NY', ShippingStreet='123 Main St', BillingStreet='234 Main St', ShippingPostalCode='14624', BillingPostalCode='14624');
       Account acct5 = new Account(Name='Account5', ShippingState='NY', ShippingStreet='123 Main St', ShippingPostalCode='14624');
       Account acct6 = new Account(Name='Account6', ShippingState='NY', ShippingStreet='123 Main St', ShippingPostalCode='14624');
       Account acct7 = new Account(Name='Account7', ShippingState='ON', ShippingPostalCode='L4N5H',BillingState='QC', Legal_State__c='ON', Legal_Postal_Code__c='L4N5H');
       Account acct8 = new Account(Name='Account8', BillingStreet='123  Main  St', ShippingStreet='234  Main  St',LegalAddress__Street__s='456 Main  St');
       insert new Account[]{acct1,acct2,acct3,acct4,acct5,acct6,acct7,acct8};
       Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Name, BillingUUID__c, ShippingUUID__c
                                        ,BillingStreet, BillingState, BillingCountry, BillingPostalCode
                                        ,ShippingStreet, ShippingState, ShippingCountry, ShippingPostalCode
                                        ,Legal_Street__c, Legal_City__c, Legal_State__c, Legal_Postal_Code__c
                                        ,LegalAddress__Street__s, LegalAddress__City__s, LegalAddress__StateCode__s, LegalAddress__PostalCode__s, LegalAddress__CountryCode__s
                                    From Account]);
       acct1 = acctMap.get(acct1.Id);
       Assert.areEqual('US',acct1.ShippingCountry);
       Assert.areEqual('US',acct1.BillingCountry);
       Assert.areEqual('NY',acct1.ShippingState);
       Assert.areEqual('VT',acct1.BillingState);
       Assert.isNull(acct1.Legal_State__c);
       Assert.areEqual('123 Main Street', acct1.LegalAddress__Street__s);
       Assert.areEqual('Rochester',acct1.LegalAddress__City__s); 
       Assert.isNull(acct1.LegalAddress__StateCode__s);
       Assert.areEqual('14624',acct1.LegalAddress__PostalCode__s);
       Assert.areEqual('US',acct1.LegalAddress__CountryCode__s);
        
       acct2 = acctMap.get(acct2.Id);
       Assert.areEqual('US',acct2.ShippingCountry);
       Assert.areEqual('US',acct2.BillingCountry);
       Assert.areEqual('NY',acct2.ShippingState);
       Assert.areEqual('Not A State',acct2.BillingState);
       Assert.areEqual('NY',acct2.Legal_State__c);
       Assert.areEqual(null, acct2.LegalAddress__Street__s);
       Assert.areEqual('Rochester',acct2.LegalAddress__City__s); 
       Assert.areEqual('NY',acct2.LegalAddress__StateCode__s);
       Assert.areEqual('14624',acct2.LegalAddress__PostalCode__s);
       Assert.areEqual('US',acct2.LegalAddress__CountryCode__s);

       acct3 = acctMap.get(acct3.Id);
       Assert.isNotNull(acct3.BillingUUID__c);
       Assert.isNotNull(acct3.ShippingUUID__c);
       Assert.areEqual(acct3.BillingUUID__c, acct3.ShippingUUID__c);
        
       acct4 = acctMap.get(acct4.Id);
       Assert.isNotNull(acct4.BillingUUID__c);
       Assert.isNotNull(acct4.ShippingUUID__c);
       Assert.areNotEqual(acct4.BillingUUID__c, acct4.ShippingUUID__c);

       acct5 = acctMap.get(acct5.Id);
       Assert.isNull(acct5.BillingUUID__c);
       Assert.isNotNull(acct5.ShippingUUID__c);

       acct6 = acctMap.get(acct6.Id);
       Assert.isNull(acct6.BillingUUID__c);
       Assert.isNotNull(acct6.ShippingUUID__c);
        
       acct7 = acctMap.get(acct7.Id);
       Assert.areEqual('CA',acct7.ShippingCountry);
       Assert.areEqual('CA',acct7.BillingCountry);
       Assert.areEqual('CA',acct7.LegalAddress__CountryCode__s);

       acct8 = acctMap.get(acct8.Id);
       Assert.areEqual('123 Main St',acct8.BillingStreet);
       Assert.areEqual('234 Main St',acct8.ShippingStreet);
       Assert.areEqual('456 Main St',acct8.LegalAddress__Street__s);
        
       acct5.BillingStreet = acct5.ShippingStreet;
       acct5.BillingPostalCode = acct5.ShippingPostalCode;
        
       acct6.BillingStreet = '567 Another St';
       acct6.BillingPostalCode = '14514';
       TriggerMethods.clearVariables();
       update new Account[]{acct5,acct6};
           

       acctMap = new Map<Id,Account>([Select Id, Name, BillingUUID__c, ShippingUUID__c
                                        ,BillingStreet, BillingState, BillingCountry, BillingPostalCode
                                        ,ShippingStreet, ShippingState, ShippingCountry, ShippingPostalCode
                                        ,Legal_Street__c, Legal_City__c, Legal_State__c, Legal_Postal_Code__c
                                        ,LegalAddress__Street__s, LegalAddress__City__s, LegalAddress__StateCode__s, LegalAddress__PostalCode__s, LegalAddress__CountryCode__s
                                    From Account]);
        
       acct5 = acctMap.get(acct5.Id);
       Assert.isNotNull(acct5.BillingUUID__c);
       Assert.isNotNull(acct5.ShippingUUID__c);
       Assert.areEqual(acct5.BillingUUID__c, acct5.ShippingUUID__c);

       acct6 = acctMap.get(acct6.Id);
       Assert.isNotNull(acct6.BillingUUID__c);
       Assert.isNotNull(acct6.ShippingUUID__c);
       Assert.areNotEqual(acct6.BillingUUID__c, acct6.ShippingUUID__c);


    } // testAcctAddressInfo
    
    static testMethod void testAcctAddressInfo2() {
       ZipCodeInformationTest.setupZips();

       Account acct1 = new Account(Name='Account1', ShippingPostalCode=ZipCodeInformationTest.zci7.Name, BillingPostalCode=ZipCodeInformationTest.zci7.Name);
       Account acct2 = new Account(Name='Account2', ShippingPostalCode=ZipCodeInformationTest.zci2.Name, BillingPostalCode=ZipCodeInformationTest.zci2.Name);
       Account acct3 = new Account(Name='Account3', ShippingPostalCode=ZipCodeInformationTest.zci2.Name, BillingPostalCode=ZipCodeInformationTest.zci7.Name);
       insert new Account[]{acct1,acct2,acct3};

       Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Name
                                        ,BillingCity, BillingState, BillingCountry
                                        ,ShippingCity, ShippingState, ShippingCountry
                                        ,TimeZoneAbbrev__c, TimeZoneName__c
                                    From Account]);
       acct1 = acctMap.get(acct1.Id);
       Assert.areEqual('US',acct1.ShippingCountry);
       Assert.areEqual('US',acct1.BillingCountry);
       Assert.areEqual(ZipCodeInformationTest.zci7.TimeZoneAbbrev__c, acct1.TimeZoneAbbrev__c);
       Assert.areEqual(ZipCodeInformationTest.zci7.TimeZoneName__c, acct1.TimeZoneName__c);
       Assert.areEqual(ZipCodeInformationTest.zci7.City__c,acct1.ShippingCity);
       Assert.areEqual(ZipCodeInformationTest.zci7.City__c,acct1.BillingCity);
       Assert.areEqual(ZipCodeInformationTest.zci7.State__c,acct1.ShippingState);
       Assert.areEqual(ZipCodeInformationTest.zci7.State__c,acct1.BillingState);
        
       acct2 = acctMap.get(acct2.Id);
       Assert.areEqual('US',acct2.ShippingCountry);
       Assert.areEqual('US',acct2.BillingCountry);
       Assert.areEqual(ZipCodeInformationTest.zci2.TimeZoneAbbrev__c, acct2.TimeZoneAbbrev__c);
       Assert.areEqual(ZipCodeInformationTest.zci2.TimeZoneName__c, acct2.TimeZoneName__c);
       Assert.areEqual(ZipCodeInformationTest.zci2.City__c,acct2.ShippingCity);
       Assert.areEqual(ZipCodeInformationTest.zci2.City__c,acct2.BillingCity);
       Assert.areEqual(ZipCodeInformationTest.zci2.State__c,acct2.ShippingState);
       Assert.areEqual(ZipCodeInformationTest.zci2.State__c,acct2.BillingState);

       acct3 = acctMap.get(acct3.Id);
       Assert.areEqual('US',acct3.ShippingCountry);
       Assert.areEqual('US',acct3.BillingCountry);
       Assert.areEqual(ZipCodeInformationTest.zci2.TimeZoneAbbrev__c, acct3.TimeZoneAbbrev__c);
       Assert.areEqual(ZipCodeInformationTest.zci2.TimeZoneName__c, acct3.TimeZoneName__c);
       Assert.areEqual(ZipCodeInformationTest.zci2.City__c,acct3.ShippingCity);
       Assert.areEqual(ZipCodeInformationTest.zci7.City__c,acct3.BillingCity);
       Assert.areEqual(ZipCodeInformationTest.zci2.State__c,acct3.ShippingState);
       Assert.areEqual(ZipCodeInformationTest.zci7.State__c,acct3.BillingState);
    } // testAcctAddressInfo2
    
    static testMethod void testStateCode() {
       Assert.isNull(TimeZoneHelper.verifyStateCode('XX'));
       Assert.areEqual('NY', TimeZoneHelper.verifyStateCode('NY'));
       Assert.areEqual('NY', TimeZoneHelper.verifyStateCode('ny'));
    } // testStateCode
    
   static testMethod void testContacts() {
      TimeZoneHelper.CLEAR_INVALID_STATE=true;
      TimeZoneHelper.ALWAYS_SET_CITY_STATE=true;

      Zip_Code_Information__c zci1 = new Zip_Code_Information__c(Name='14624',TimeZoneAbbrev__c='ET',City__c='Rochester', State__c='NY');
      Zip_Code_Information__c zci2 = new Zip_Code_Information__c(Name='37205',TimeZoneAbbrev__c='CT',City__c='Nashville', State__c='TN'
                                                                 ,Zip_Geo__Latitude__s=36.112006000, Zip_Geo__Longitude__s=-86.868337000);
      Zip_Code_Information__c zci3 = new Zip_Code_Information__c(Name='90210',TimeZoneAbbrev__c='PT',City__c='Beverly Hills', State__c='CA'
                                                                 ,Zip_Geo__Latitude__s=34.103131000, Zip_Geo__Longitude__s=-118.416253000);
      Zip_Code_Information__c[] zcis = new Zip_Code_Information__c[]{zci1,zci2,zci3};
      insert zcis;
       
      Contact ctct1 = new Contact(LastName='Contact1', MailingStreet='123 Main St', MailingCity='Rochester',MailingState='New York', MailingPostalCode=zci1.Name
                                 ,OtherStreet='124 Main St', OtherCity='Rachacha', OtherState=null, OtherPostalCode=zci2.Name);
      Contact ctct2 = new Contact(LastName='Contact2', MailingStreet='125 Main St', MailingCity='Rochester',MailingState='NY', MailingPostalCode=zci1.Name
                                 ,OtherStreet='126 Main St', OtherCity=null, OtherState=null, OtherPostalCode=zci3.Name);
      insert new Contact[]{ctct1,ctct2};
          
      Map<Id,Contact> ctctMap = new Map<Id,Contact>([Select Id, LastName, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry
                                                           ,OtherStreet, OtherCity, OtherState, OtherPostalCode, OtherCountry, OtherLatitude, OtherLongitude
                                                       From Contact]);
      ctct1 = ctctMap.get(ctct1.Id);
      Assert.areEqual(zci1.City__c, ctct1.MailingCity);
      Assert.areEqual(zci1.State__c, ctct1.MailingState);
      Assert.areEqual('US',ctct1.MailingCountry);
      Assert.areEqual(zci2.City__c, ctct1.OtherCity);
      Assert.areEqual(zci2.State__c, ctct1.OtherState);
      Assert.areEqual('US',ctct1.OtherCountry);
      Assert.areEqual(zci2.Zip_Geo__Latitude__s, ctct1.OtherLatitude);
      Assert.areEqual(zci2.Zip_Geo__Longitude__s, ctct1.OtherLongitude);
       
      ctct2 = ctctMap.get(ctct2.Id);
      Assert.areEqual(zci1.City__c, ctct2.MailingCity);
      Assert.areEqual(zci1.State__c, ctct2.MailingState);
      Assert.areEqual('US',ctct2.MailingCountry);
      Assert.areEqual(zci3.City__c, ctct2.OtherCity);
      Assert.areEqual(zci3.State__c, ctct2.OtherState);
      Assert.areEqual('US',ctct2.OtherCountry);
      Assert.areEqual(zci3.Zip_Geo__Latitude__s, ctct2.OtherLatitude);
      Assert.areEqual(zci3.Zip_Geo__Longitude__s, ctct2.OtherLongitude);
      
   } // testContacts
    
   static testMethod void testUser() {
      TimeZoneHelper.CLEAR_INVALID_STATE=true;
      TimeZoneHelper.ALWAYS_SET_CITY_STATE=true;

      Zip_Code_Information__c zci1 = new Zip_Code_Information__c(Name='14624',TimeZoneAbbrev__c='ET',City__c='Rochester', State__c='NY');
      Zip_Code_Information__c zci2 = new Zip_Code_Information__c(Name='37205',TimeZoneAbbrev__c='CT',City__c='Nashville', State__c='TN');
      Zip_Code_Information__c zci3 = new Zip_Code_Information__c(Name='90210',TimeZoneAbbrev__c='PT',City__c='Beverly Hills', State__c='CA');
      Zip_Code_Information__c[] zcis = new Zip_Code_Information__c[]{zci1,zci2,zci3};
      insert zcis;
       
      User[] usrs = [Select Id, Name, Street, City, State, PostalCode, Country 
                       From User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 3];
      User runningUser = UserHelper.getRunningUser();
      User usr1 = usrs[0];
      usr1.PostalCode = zci1.Name;
      User usr2 = usrs[1];
      usr2.PostalCode = zci2.Name;
      User usr3 = usrs[2];
      usr3.PostalCode = zci3.Name;
      System.runAs(runningUser) {
         update new User[]{usr1,usr2,usr3};
      }
      Id[] userIds = new Id[]{usr1.Id,usr2.Id,usr3.Id};  
      Map<Id,User> usrMap = new Map<Id,User>([Select Id, Name, Street, City, State, PostalCode, Country
                                                       From User where Id in :userIds]);
      usr1 = usrMap.get(usr1.Id);
      Assert.areEqual(zci1.City__c, usr1.City);
      Assert.areEqual(zci1.State__c, usr1.State);
      Assert.areEqual('US',usr1.Country);
       
      usr2 = usrMap.get(usr2.Id);
      Assert.areEqual(zci2.City__c, usr2.City);
      Assert.areEqual(zci2.State__c, usr2.State);
      Assert.areEqual('US',usr2.Country);

      usr3 = usrMap.get(usr3.Id);
      Assert.areEqual(zci3.City__c, usr3.City);
      Assert.areEqual(zci3.State__c, usr3.State);
      Assert.areEqual('US',usr3.Country);

   } // testUser
    
   static testMethod void testAddrIds() {
      Account acct1 = new Account(Name='Account 1', ShippingStreet='123 Main St', ShippingPostalCode='14624', BillingStreet='123 Main St', BillingPostalCode='14624');
      TimeZoneHelper.checkAddrUUID(acct1, null);
      Assert.isNotNull(acct1.BillingUUID__c);
      Assert.isNotNull(acct1.ShippingUUID__c);
      Assert.areEqual(acct1.BillingUUID__c, acct1.ShippingUUID__c, 'Not Equal! Billing='+acct1.BillingUUID__c+' Shipping='+acct1.ShippingUUID__c);
       
      Account acct2 = acct1.clone(false,true);
      acct2.BillingStreet = '234 South Ave';
      TimeZoneHelper.checkAddrUUID(acct2, acct1);
      Assert.isNotNull(acct2.BillingUUID__c);
      Assert.isNotNull(acct2.ShippingUUID__c);
      Assert.areNotEqual(acct2.BillingUUID__c, acct2.ShippingUUID__c, 'Should not be equal! Billing='+acct2.BillingUUID__c+' Shipping='+acct2.ShippingUUID__c);
      
      Account acct3 = acct2.clone(false,true);
      acct3.BillingStreet = '123 Main St';
      TimeZoneHelper.checkAddrUUID(acct3, acct2);
      Assert.isNotNull(acct3.BillingUUID__c);
      Assert.isNotNull(acct3.ShippingUUID__c);
      Assert.areEqual(acct3.BillingUUID__c, acct3.ShippingUUID__c, 'Should be equal! Billing='+acct2.BillingUUID__c+' Shipping='+acct2.ShippingUUID__c);
       
      Account acct4 = acct3.clone(false,true);
      acct4.ShippingPostalCode = '14624-1234';
      TimeZoneHelper.checkAddrUUID(acct4, acct3);
      // these should not have changed
      Assert.areEqual(acct3.BillingUUID__c,acct4.BillingUUID__c);
      Assert.areEqual(acct3.ShippingUUID__c,acct4.ShippingUUID__c);
       
      Account acct5 = new Account(Name='Account 5', ShippingStreet='123 Main St', ShippingPostalCode='14624');
      TimeZoneHelper.checkAddrUUID(acct5, null);
      Assert.isNull(acct5.BillingUUID__c);
      Assert.isNotNull(acct5.ShippingUUID__c);
      //Assert.areEqual(acct1.BillingUUID__c, acct1.ShippingUUID__c, 'Not Equal! Billing='+acct1.BillingUUID__c+' Shipping='+acct1.ShippingUUID__c);

      Account acct6 = acct5.clone(false,true);
      acct6.BillingStreet='123 Main St';
      acct6.BillingPostalCode='14624';
      TimeZoneHelper.checkAddrUUID(acct6, acct5);
      Assert.isNotNull(acct6.BillingUUID__c);
      Assert.isNotNull(acct6.ShippingUUID__c);
      Assert.areEqual(acct6.BillingUUID__c, acct6.ShippingUUID__c, 'Not Equal! Billing='+acct6.BillingUUID__c+' Shipping='+acct6.ShippingUUID__c);

      Account acct7 = new Account(Name='Account 5', BillingStreet='123 Main St', BillingPostalCode='14624');
      TimeZoneHelper.checkAddrUUID(acct7, null);
      Assert.isNotNull(acct7.BillingUUID__c);
      Assert.isNull(acct7.ShippingUUID__c);
      //Assert.areEqual(acct1.BillingUUID__c, acct1.ShippingUUID__c, 'Not Equal! Billing='+acct1.BillingUUID__c+' Shipping='+acct1.ShippingUUID__c);

      Account acct8 = acct7.clone(false,true);
      acct8.ShippingStreet='123 Main St';
      acct8 .ShippingPostalCode='14624';
      TimeZoneHelper.checkAddrUUID(acct8, acct7);
      Assert.isNotNull(acct8.BillingUUID__c);
      Assert.isNotNull(acct8.ShippingUUID__c);
      Assert.areEqual(acct8.BillingUUID__c, acct8.ShippingUUID__c, 'Not Equal! Billing='+acct8.BillingUUID__c+' Shipping='+acct8.ShippingUUID__c);

   } // testAddrIds
    
   static testMethod void testMisc() {
      Zip_Code_Information__c zci1 = new Zip_Code_Information__c(Name='14624',TimeZoneAbbrev__c='ET',City__c='Rochester', State__c='NY');
      Zip_Code_Information__c zci2 = new Zip_Code_Information__c(Name='37205',TimeZoneAbbrev__c='CT',City__c='Nashville', State__c='TN');
      Zip_Code_Information__c zci3 = new Zip_Code_Information__c(Name='90210',TimeZoneAbbrev__c='PT',City__c='Beverly Hills', State__c='CA');
      Zip_Code_Information__c[] zcis = new Zip_Code_Information__c[]{zci1,zci2,zci3};
      insert zcis;
       
      Account acct = new Account(Name='Test Account', ShippingStreet='123     Main  St', ShippingPostalCode='14624', BillingStreet='234     Some    Road', BillingPostalCode='37205'
                                ,LegalAddress__Street__s='345    Other Lane', LegalAddress__PostalCode__s='90210', BillingValidated__c=true, ShippingValidated__c=true);
      insert acct;
      acct = [Select Id, Name, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, ShippingValidated__c, ShippingUUID__c
                              ,BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingValidated__c, BillingUUID__c
                              ,LegalAddress__Street__s, LegalAddress__City__s, LegalAddress__StateCode__s, LegalAddress__PostalCode__s, LegalAddress__CountryCode__s
               from Account where Id=:acct.Id];
      Assert.areEqual('123 Main St',acct.ShippingStreet);
      Assert.areEqual('Rochester', acct.ShippingCity);
      Assert.areEqual('NY', acct.ShippingState);
      Assert.areEqual('14624',acct.ShippingPostalCode);
      Assert.areEqual('US',acct.ShippingCountry);
      Assert.isTrue(acct.ShippingValidated__c);
      Assert.isNotNull(acct.ShippingUUID__c);
       
      Assert.areEqual('234 Some Road',acct.BillingStreet);
      Assert.areEqual('Nashville', acct.BillingCity);
      Assert.areEqual('TN', acct.BillingState);
      Assert.areEqual('37205',acct.BillingPostalCode);
      Assert.areEqual('US',acct.BillingCountry);
      Assert.isTrue(acct.BillingValidated__c);
      Assert.isNotNull(acct.BillingUUID__c);
       
      Assert.areEqual('345 Other Lane',acct.LegalAddress__Street__s);
      Assert.areEqual('Beverly Hills', acct.LegalAddress__City__s);
      Assert.areEqual('CA', acct.LegalAddress__StateCode__s);
      Assert.areEqual('90210',acct.LegalAddress__PostalCode__s);
      Assert.areEqual('US',acct.LegalAddress__CountryCode__s);

      TriggerMethods.clearVariables();
      ZipCheckOwner.SKIP_TRIGGERS=false;
      acct.ShippingStreet='456 Another  Rd';
      acct.BillingPostalCode='14624';
      update acct;
       
      acct = [Select Id, Name, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, ShippingValidated__c, ShippingUUID__c
                              ,BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingValidated__c, BillingUUID__c
                              ,LegalAddress__Street__s, LegalAddress__City__s, LegalAddress__StateCode__s, LegalAddress__PostalCode__s, LegalAddress__CountryCode__s
               from Account where Id=:acct.Id];
      Assert.isFalse(acct.BillingValidated__c);
      Assert.isFalse(acct.ShippingValidated__c);
      Assert.areEqual('456 Another Rd', acct.ShippingStreet);
      Assert.areEqual('Rochester',acct.BillingCity);
      Assert.areEqual('NY',acct.BillingState);
      
   } // testMisc
    
} // class TimeZoneHelperTest