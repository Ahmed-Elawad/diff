/* 
 * Test methods for the RecordTypeHelper class
 *
 * History
 * -------
 * 06/15/2011 Dan Carmen   Created
   07/27/2012 Dan Carmen   Added methods for the Record_Type_Mapping__c object
   10/24/2013 Cindy Freeman  Added test for getRecordTypeById
   07/14/2015 Dan Carmen     Updates to values for RecordType__c
   07/15/2015 Dan Carmen   Added getCaseRecordTypeInfo method.
   08/31/2016 Carrie Marciano changed record type names for Fast Track #21813708 From: MMS HRS or Referral Revenue Opportunity To: MMS Referral Revenue Opportunity - Rep and From: MMS HRS or Referral Rev Opp (DSA) To: MMS Referral Revenue Opportunity - DSA
   10/23/2017 Dan Carmen   Added in a check in getSalesOrgForRecordTypeName for the RecordType__c custom setting 
   11/10/2017 Dan Carmen   Add cleanRtName
   05/31/2019 Jake Hinds   add peo prospect rt
   09/03/2019 Dan Carmen        Fix query to select core sales reps
   01/03/2022 Dan Carmen        Update RecordType__c values
   12/23/2022 Pujitha Madamanchi  null check in cleanRtName

*/
@isTest
public class RecordTypeHelperTest {

   /** Test retrieving a single record type.
    */
   static testMethod void testGetOneRecordType() {
      // test that the values returned are the same
      Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT,'Account');
      RecordType rt2 = [Select Id, Name, SobjectType from RecordType where name = :RecordTypeHelper.CORE_ACCOUNT and SobjectType = 'Account'];
      System.assertEquals(rt.getRecordTypeId(),rt2.Id);
      // get another one just to make sure
      rt = RecordTypeHelper.getRecordType('MMS Account Record Type','Account');
      rt2 = [Select Id, Name, SobjectType from RecordType where name = :RecordTypeHelper.MMS_ACCOUNT and SobjectType = 'Account'];
      System.assertEquals(rt.getRecordTypeId(),rt2.Id);
      // test can get recordtype by id
      Schema.RecordTypeInfo rt3 = RecordTypeHelper.getRecordTypeById(rt.getRecordTypeId(), 'Account');
      System.assertEquals(rt.getRecordTypeId(),rt3.getRecordTypeId());
   } // testGetOneRecordType

   /** Test retrieving all record types for an object.
    */
   static testMethod void testGetAllForObject() {
      List<Schema.RecordTypeInfo> rts = RecordTypeHelper.getRecordTypes('Account');
      for (Schema.RecordTypeInfo rt : rts) {
         System.debug('RecordType name='+rt.getName()+' id='+rt.getRecordTypeId()+' available='+rt.isAvailable()+' default='+rt.isDefaultRecordTypeMapping());
      }
      RecordType[] acctRTs = [Select Id, Name, SobjectType from RecordType where SobjectType = 'Account'];
      // make sure all that are retrieved from SOQL are retrieved from the schema
      for (RecordType acctRT : acctRTs) {
         Boolean found = false;
         for (Schema.RecordTypeInfo rt : rts) {
            if (acctRT.Id == rt.getRecordTypeId()) {
               found = true;
            }
         } // for (Schema.RecordTypeId
         System.assertEquals(true,found);
      } // for (RecordType

   } // testGetAllForObject

   static testMethod void testGetMapsForObject() {
      Map<String,Schema.RecordTypeInfo> byId = new Map<String,Schema.RecordTypeInfo>();
      Map<String,Schema.RecordTypeInfo> byName = new Map<String,Schema.RecordTypeInfo>();
      RecordTypeHelper.getRecordTypesMap('Account',byId,byName);
      // verify data retrieved
      System.assertEquals(true,(byName.size() > 0));
      System.assertEquals(true,(byId.size() > 0));
      
   } // testGetMapsForObject

   static testMethod void testGetMapsForObjects() {
      Map<String,Schema.RecordTypeInfo> byId = new Map<String,Schema.RecordTypeInfo>();
      Map<String,Schema.RecordTypeInfo> byName = new Map<String,Schema.RecordTypeInfo>();
      String[] sObjects = new String[]{'Account','Contact'};
      RecordTypeHelper.getRecordTypesMap(sObjects,byId,byName);
      // verify data retrieved
      System.assertEquals(true,(byName.size() > 0));
      System.assertEquals(true,(byId.size() > 0));
      
   } // testGetMapsForObjects

   static testMethod void testGetMapsForObjectsByName() {
      Map<String,Schema.RecordTypeInfo> byId = new Map<String,Schema.RecordTypeInfo>();
      Map<String,Schema.RecordTypeInfo> byName = new Map<String,Schema.RecordTypeInfo>();
      String[] sObjects = new String[]{'Account','Contact'};
      String[] rtNames = new String[]{RecordTypeHelper.CORE_ACCOUNT,RecordTypeHelper.MMS_ACCOUNT,RecordTypeHelper.CORE_CONTACT,RecordTypeHelper.MMS_CONTACT};
      RecordTypeHelper.getRecordTypesMap(sObjects,rtNames,byId,byName);
      // verify 4 record retrieved
      System.assertEquals(4,byName.size());
      System.assertEquals(4,byId.size());
      // verify the record types are retrieved
      System.assertEquals(true,(byName.get(RecordTypeHelper.CORE_ACCOUNT) != null));
      System.assertEquals(true,(byName.get(RecordTypeHelper.MMS_ACCOUNT) != null));
      System.assertEquals(true,(byName.get(RecordTypeHelper.CORE_CONTACT) != null));
      System.assertEquals(true,(byName.get(RecordTypeHelper.MMS_CONTACT) != null));
      // verify a bad name returns nothing
      System.assertEquals(true,(byName.get('TEST TEST') == null));
      
   } // testGetMapsForObjectsByName
   
   static testMethod void testGetDefaultRecordType1() {
      // select a non sys admin user
      User u = [Select Id, Name from User where IsActive=true and Profile.Name like :Utilities.PROF_CORE_SALES+'%' limit 1];
      System.runAs(u) {
         Schema.RecordTypeInfo rt = RecordTypeHelper.getDefaultRecordType('Task');
         System.debug('User id='+u.Id+' Name='+u.Name+' record type='+rt.getName());
         System.assertEquals(true,(rt != null));
         System.assertEquals('Core Task Record Type',rt.getName());
      } // System.runAs
   } // testGetDefaultRecordType
   
   static testMethod void testGetDefaultRecordType2() {
      // select a non sys admin user
      User u = [Select Id, Name from User where IsActive=true and Profile.Name = 'System Administrator' limit 1];
      System.runAs(u) {
         Schema.RecordTypeInfo rt = RecordTypeHelper.getDefaultRecordType('Task');
         System.debug('User id='+u.Id+' Name='+u.Name+' record type='+rt.getName());
         System.assertEquals(true,(rt != null));
         System.assertEquals('Sys Admin Task Record Type',rt.getName());
      } // System.runAs
   } // testGetDefaultRecordType
   
   static testMethod void testGetSalesOrgForRecordTypeName() {
      System.assertEquals(null,RecordTypeHelper.getSalesOrgForRecordTypeName(null));
      System.assertEquals(null,RecordTypeHelper.getSalesOrgForRecordTypeName('Test Record Type Name'));
      System.assertEquals(UserHelper.SO_CORE,RecordTypeHelper.getSalesOrgForRecordTypeName('Core Opportunity DSA Record Type'));
      System.assertEquals(UserHelper.SO_CORE,RecordTypeHelper.getSalesOrgForRecordTypeName('Core Opportunity Record Type'));
      System.assertEquals(UserHelper.SO_CORE,RecordTypeHelper.getSalesOrgForRecordTypeName('Core Referral Revenue Opportunity Record Type - DSA'));
      System.assertEquals(UserHelper.SO_CORE,RecordTypeHelper.getSalesOrgForRecordTypeName('Core Referral Revenue Opportunity Record Type - Rep'));
      System.assertEquals(UserHelper.SO_401,RecordTypeHelper.getSalesOrgForRecordTypeName('HRS 401(k) Opportunity FSS Record Type'));
      System.assertEquals(UserHelper.SO_401,RecordTypeHelper.getSalesOrgForRecordTypeName('HRS 401(k) Opportunity Record Type'));
      System.assertEquals(UserHelper.SO_401,RecordTypeHelper.getSalesOrgForRecordTypeName('HRS 401(k) Quick Not Sold Record Type'));
      System.assertEquals(UserHelper.SO_401,RecordTypeHelper.getSalesOrgForRecordTypeName('HRS 401(k) Referral Revenue Opportunity Rep'));
      System.assertEquals(UserHelper.SO_HNB,RecordTypeHelper.getSalesOrgForRecordTypeName('HRS HNBF Opportunity DSA Record Type'));
      System.assertEquals(UserHelper.SO_HNB,RecordTypeHelper.getSalesOrgForRecordTypeName('HRS HNBF Opportunity Record Type'));
      System.assertEquals(UserHelper.SO_HNB,RecordTypeHelper.getSalesOrgForRecordTypeName('HRS HNBF Referral Revenue Opportunity'));
      System.assertEquals(UserHelper.SO_PEO_ASO,RecordTypeHelper.getSalesOrgForRecordTypeName('HRS PEO-ASO Opportunity FSS Record Type'));
      System.assertEquals(UserHelper.SO_PEO_ASO,RecordTypeHelper.getSalesOrgForRecordTypeName('HRS PEO-ASO Opportunity Record Type'));
      System.assertEquals(UserHelper.SO_PEO_ASO,RecordTypeHelper.getSalesOrgForRecordTypeName('HRS PEO-ASO Referral Revenue Opportunity'));
      System.assertEquals(UserHelper.SO_MMS,RecordTypeHelper.getSalesOrgForRecordTypeName('MMS Referral Revenue Opportunity - DSA'));
      System.assertEquals(UserHelper.SO_MMS,RecordTypeHelper.getSalesOrgForRecordTypeName('MMS Referral Revenue Opportunity - Rep'));
      System.assertEquals(UserHelper.SO_MMS,RecordTypeHelper.getSalesOrgForRecordTypeName('MMS Opportunity (DSA) Record Type'));
      System.assertEquals(UserHelper.SO_MMS,RecordTypeHelper.getSalesOrgForRecordTypeName('MMS Opportunity Record Type'));
      
      // to hit the other part of code
      UserHelperTest.setupSalesOrgSetting();
      System.assertEquals(UserHelper.SO_CORE,RecordTypeHelper.getSalesOrgForRecordTypeName('Core Opportunity DSA Record Type'));
      System.assertEquals(UserHelper.SO_MMS,RecordTypeHelper.getSalesOrgForRecordTypeName('MMS Opportunity Record Type'));
   } // testGetSalesOrgForRecordTypeName
   
   static testMethod void testisDSAOpptyRT() {
      System.assertEquals(false,RecordTypeHelper.isDSAOpptyRT(null));
      System.assertEquals(false,RecordTypeHelper.isDSAOpptyRT('Bla Bla'));
      System.assertEquals(false,RecordTypeHelper.isDSAOpptyRT('This is NOT an Opportunity for a District Sales Assistant'));
      System.assertEquals(true,RecordTypeHelper.isDSAOpptyRT('This IS an Opportunity for a DSA'));
      System.assertEquals(true,RecordTypeHelper.isDSAOpptyRT('Core Opportunity DSA Record Type'));
      System.assertEquals(false,RecordTypeHelper.isDSAOpptyRT('Core Opportunity Record Type'));
      System.assertEquals(true,RecordTypeHelper.isDSAOpptyRT('Core Referral Revenue Opportunity Record Type - DSA'));
      System.assertEquals(false,RecordTypeHelper.isDSAOpptyRT('Core Referral Revenue Opportunity Record Type - Rep'));
      System.assertEquals(true,RecordTypeHelper.isDSAOpptyRT('HRS 401(k) Opportunity FSS Record Type'));
      System.assertEquals(false,RecordTypeHelper.isDSAOpptyRT('HRS 401(k) Opportunity Record Type'));
      System.assertEquals(false,RecordTypeHelper.isDSAOpptyRT('HRS 401(k) Quick Not Sold Record Type'));
      System.assertEquals(false,RecordTypeHelper.isDSAOpptyRT('HRS 401(k) Referral Revenue Opportunity Rep'));
      System.assertEquals(true,RecordTypeHelper.isDSAOpptyRT('HRS HNBF Opportunity DSA Record Type'));
      System.assertEquals(false,RecordTypeHelper.isDSAOpptyRT('HRS HNBF Opportunity Record Type'));
      System.assertEquals(false,RecordTypeHelper.isDSAOpptyRT('HRS HNBF Referral Revenue Opportunity'));
      System.assertEquals(true,RecordTypeHelper.isDSAOpptyRT('HRS PEO-ASO Opportunity FSS Record Type'));
      System.assertEquals(false,RecordTypeHelper.isDSAOpptyRT('HRS PEO-ASO Opportunity Record Type'));
      System.assertEquals(false,RecordTypeHelper.isDSAOpptyRT('HRS PEO-ASO Referral Revenue Opportunity'));
      System.assertEquals(true,RecordTypeHelper.isDSAOpptyRT('MMS Referral Revenue Opportunity - DSA'));
      System.assertEquals(false,RecordTypeHelper.isDSAOpptyRT('MMS Referral Revenue Opportunity - Rep'));
      System.assertEquals(true,RecordTypeHelper.isDSAOpptyRT('MMS Opportunity (DSA) Record Type'));
      System.assertEquals(false,RecordTypeHelper.isDSAOpptyRT('MMS Opportunity Record Type'));
      
   } // testisDSAOpptyRT
   
   static testMethod void testInsert() {
      Integer[] testArray = new Integer[]{};
      testArray.add(47);
      System.assertEquals(1,testArray.size());
      testArray.add(0,50);
      System.assertEquals(2,testArray.size());
      System.assertEquals(50,testArray.get(0));
      System.assertEquals(47,testArray.get(1));
   }
   
   static testMethod void testProspectClientRT() {
      Schema.RecordTypeInfo rt1 = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_LEAD, ObjectHelper.OBJECT_LEAD);
      Schema.RecordTypeInfo rt2 = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
      System.assertEquals(false,RecordTypeHelper.isProspectClientRT(rt1.getRecordTypeId()));
      System.assertEquals(true,RecordTypeHelper.isProspectClientRT(rt2.getRecordTypeId()));
   } // testProspectClientRT
   
   static testMethod void testGetRtSetting() {
      RecordType__c rt1 = new RecordType__c(Name='Test1');
      String longName = 'This is a test of a very long name to make sure it finds it correctly';
      String longName2 = longName.left(RecordTypeHelper.NAME_FIELD_LENGTH).trim();
      RecordType__c rt2 = new RecordType__c(Name=longName2);
      RecordType__c[] rts = new RecordType__c[]{rt1,rt2};
      insert rts;
      
      System.assertEquals(true, RecordTypeHelper.getRtSetting('Bad Name') == null);
      System.assertEquals(rt1.Id, RecordTypeHelper.getRtSetting('Test1').Id);
      System.assertEquals(rt2.Id, RecordTypeHelper.getRtSetting('This is a test of a very long name to make sure it finds it correctly').Id);
   } // testGetRtSetting
   
   public static void setupRecordType() {
      // make sure they're not already setup
      //Integer nbrRecTypes = RecordType__c.getAll().size();
      //System.debug('setupRecordType nbrRecTypes='+nbrRecTypes);
      //if (nbrRecTypes > 0) {
      //   return;
      //}
      RecordType__c[] recordTypes = new RecordType__c[]{};
      Set<String> rtNames= new Set<String>();
      rtNames.addAll(RecordType__c.getall().keySet());
      if (!rtNames.contains(RecordTypeHelper.CORE_ACCOUNT)) {
         recordTypes.add(new RecordType__c(Name=RecordTypeHelper.CORE_ACCOUNT,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,RecordTypeName__c=RecordTypeHelper.CORE_ACCOUNT, Sales_Org__c=UserHelper.SO_CORE, UsedInOwnership__c=true,EmpsMin__c=0,EmpsMax__c=49
                                             ,ContactRecordTypeName__c=RecordTypeHelper.CORE_CONTACT));
      }
      if (!rtNames.contains(RecordTypeHelper.MMS_ACCOUNT)) {
         recordTypes.add(new RecordType__c(Name=RecordTypeHelper.MMS_ACCOUNT,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,RecordTypeName__c=RecordTypeHelper.MMS_ACCOUNT, Sales_Org__c=UserHelper.SO_MMS, UsedInOwnership__c=true,EmpsMin__c=50,EmpsMax__c=999999
                                             ,ContactRecordTypeName__c=RecordTypeHelper.MMS_CONTACT));
      }
      if (!rtNames.contains(RecordTypeHelper.CORE_LEAD)) {
         recordTypes.add(new RecordType__c(Name=RecordTypeHelper.CORE_LEAD,ObjectName__c=ObjectHelper.OBJECT_LEAD,RecordTypeName__c=RecordTypeHelper.CORE_LEAD, Sales_Org__c=UserHelper.SO_CORE, UsedInOwnership__c=true));
      }
      if (!rtNames.contains(RecordTypeHelper.MMS_LEAD)) {
         recordTypes.add(new RecordType__c(Name=RecordTypeHelper.MMS_LEAD,ObjectName__c=ObjectHelper.OBJECT_LEAD,RecordTypeName__c=RecordTypeHelper.MMS_LEAD, Sales_Org__c=UserHelper.SO_MMS, UsedInOwnership__c=true));
      }
      if (!rtNames.contains(RecordTypeHelper.HRS_LEAD)) {
         recordTypes.add(new RecordType__c(Name=RecordTypeHelper.HRS_LEAD,ObjectName__c=ObjectHelper.OBJECT_LEAD,RecordTypeName__c=RecordTypeHelper.HRS_LEAD, Sales_Org__c=UserHelper.SO_401, UsedInOwnership__c=true));
      }
      if (!rtNames.contains(Label.RT_Prospect_Acct)) {
         recordTypes.add(new RecordType__c(Name=Label.RT_Prospect_Acct,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,RecordTypeName__c=Label.RT_Prospect_Acct, Sales_Org__c=UserHelper.SO_PEO, UsedInOwnership__c=true));
      }
      if (!rtNames.contains(RecordTypeHelper.CORE_REFERRAL_ACCOUNT)) {
         recordTypes.add(new RecordType__c(Name=RecordTypeHelper.CORE_REFERRAL_ACCOUNT, UsedInOwnership__c=true
                                              ,RecordTypeName__c=RecordTypeHelper.CORE_REFERRAL_ACCOUNT, Sales_Org__c=UserHelper.SO_CORE
                                              ,ObjectName__c=ObjectHelper.OBJECT_REF_ACCOUNT, ContactRecordTypeName__c=RecordTypeHelper.CORE_REFERRAL_CONTACT));
      }
      if (!rtNames.contains(RecordTypeHelper.CORE_REFERRAL_CONTACT)) {
         recordTypes.add(new RecordType__c(Name=RecordTypeHelper.CORE_REFERRAL_CONTACT, UsedInOwnership__c=true
                                              ,RecordTypeName__c=RecordTypeHelper.CORE_REFERRAL_CONTACT, Sales_Org__c=UserHelper.SO_CORE
                                              ,ObjectName__c=ObjectHelper.OBJECT_REF_CONTACT, ParentObjectName__c=ObjectHelper.OBJECT_REF_ACCOUNT));
      }
      if (!rtNames.contains(RecordTypeHelper.HRS_REFERRAL_CONTACT)) {
         recordTypes.add(new RecordType__c(Name=RecordTypeHelper.HRS_REFERRAL_CONTACT, UsedInOwnership__c=true
                                              ,RecordTypeName__c=RecordTypeHelper.HRS_REFERRAL_CONTACT, Sales_Org__c=UserHelper.SO_401
                                              ,ObjectName__c=ObjectHelper.OBJECT_REF_CONTACT, ParentObjectName__c=ObjectHelper.OBJECT_REF_ACCOUNT));
      }
      if (!rtNames.contains(RecordTypeHelper.CORE_CONTACT)) {
         recordTypes.add(new RecordType__c(Name=RecordTypeHelper.CORE_CONTACT, UsedInOwnership__c=true
                                              ,RecordTypeName__c=RecordTypeHelper.CORE_CONTACT, Sales_Org__c=UserHelper.SO_CORE
                                              ,ObjectName__c=ObjectHelper.OBJECT_CONTACT, ParentObjectName__c=ObjectHelper.OBJECT_ACCOUNT
                                              ,DefaultSalesContact__c=true));
      }
      if (!rtNames.contains(RecordTypeHelper.MMS_CONTACT)) {
         recordTypes.add(new RecordType__c(Name=RecordTypeHelper.MMS_CONTACT, UsedInOwnership__c=true
                                              ,RecordTypeName__c=RecordTypeHelper.MMS_CONTACT, Sales_Org__c=UserHelper.SO_MMS
                                              ,ObjectName__c=ObjectHelper.OBJECT_CONTACT, ParentObjectName__c=ObjectHelper.OBJECT_ACCOUNT
                                              ,DefaultSalesContact__c=true));
      }
      System.debug('setupRecordType inserting '+recordTypes.size()+' RecordType__c settings');
      insert recordTypes;
   } // setupRecordType

   static testMethod void testGetRecordTypeInfo() {
      System.assertEquals(null,RecordTypeHelper.getCaseRecordTypeInfo('ThisIsABadRecordType'));
      System.assertEquals(null,RecordTypeHelper.getAccountRecordTypeInfo('ThisIsABadRecordType'));
      System.assertEquals(true,(RecordTypeHelper.getAccountRecordTypeInfo(RecordTypeHelper.CORE_ACCOUNT) != null));
      
      System.assertEquals(null,RecordTypeHelper.getContactRecordTypeInfo('ThisIsABadRecordType'));
      System.assertEquals(true,(RecordTypeHelper.getContactRecordTypeInfo(RecordTypeHelper.CORE_CONTACT) != null));
   } // testGetRecordTypeInfo
   
} // class RecordTypeHelperTest