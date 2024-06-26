/* 
 * Test methods for ObjectHelper class
 *
 * History
 * -------
 * 11/17/2011 Dan Carmen   Created - rewrite of the SObjectHelper class
   12/13/2012 Dan Carmen   Clean up code
   04/04/2013 Cindy Freeman added tests for FieldType
   07/09/2013 Dan Carmen   Get object prefix
   12/01/2013 Dan Carmen   Added getSOQLQuery method.
   01/28/2014 Justin Henderson   Added overload method for getFieldLength.
   02/13/2014 Cindy Freeman      Added prefix, getSOQLQuery and getLookupFieldMap methods from config02
   03/01/2014 Dan Carmen   Changes for NSS
   06/12/2014 Dan Carmen   Changes to handle the lead hold out field
   02/10/2016 Dan Carmen   Added formatStringAsObject method
   06/14/16 Jermaine Stukes Added getCreatableFields
   12/14/2016 Dan Carmen   Additional functionality for the formatStringAsObject method.
   09/26/2017 Dan Carmen   Added getObjectNameFromId and getObjectNameFromPrefix methods
   04/09/2018 Dan Carmen   Add cache to getSOQLQuery
   04/09/2020 Dan Carmen        Remove getRecordTypeName method
   05/27/2020 Dan Carmen        Changes for the new PEO owner fields.
   10/12/2020 Dan Carmen        Changes to formatStringAsObject for an EMAIL field 
   08/04/2021 Dan Carmen        Add getObjectLabelFromId method
   03/07/2022 Dan Carmen        Fix for formatStringAsObject to handle negative numbers

 */
@isTest
private class ObjectHelperTest {

   // Test the SObjectType methods.
   static testMethod void testSObjectType() {
      ObjectHelper soHelper = new ObjectHelper();
      System.assertEquals(null,soHelper.getSObjectType('ThisIsNotAnObject'));
      System.assertEquals(Schema.SObjectType.Case.getSobjectType(),soHelper.getSObjectType('Case'));
   } // testSObjectType
   
   // Test for the existence of an object and if you have access.
   static testMethod void testCheckObject() {
      ObjectHelper soHelper = new ObjectHelper();
      // test bad name
      System.assertEquals(false,soHelper.checkObject(null,null));
      System.assertEquals(false,soHelper.checkObject('ThisIsNotAnObject',null));
      System.assertEquals(true,soHelper.checkObject('Account',null));
      System.assertEquals(true,soHelper.checkObject('Account',ObjectHelper.ACTION_ACCESS));
      System.assertEquals(true,soHelper.checkObject('Account',ObjectHelper.ACTION_UPDATE));
      System.assertEquals(true,soHelper.checkObject('Account',ObjectHelper.ACTION_CREATE));
      System.assertEquals(false,soHelper.checkObject('Account',ObjectHelper.ACTION_WRITE_READ));
      System.assertEquals(false,soHelper.checkObject('Account','thisisnotarealaction'));
   } // testCheckObject
   
   // Test for the existence of a field on an object. 
   static testMethod void testSObjectField() {
      ObjectHelper soHelper = new ObjectHelper();
      // test with fake object
      System.assertEquals(false,soHelper.checkField('ThisIsNotAnObject','ThisIsNotAFieldName'));
      // test with real object and fake field name
      System.assertEquals(false,soHelper.checkField('Account','ThisIsNotAFieldName'));
      // test with real object and real field name
      System.assertEquals(true,soHelper.checkField('Account','Name'));
      // test different access levels
      System.assertEquals(true,soHelper.checkField('Account','Name',null));
      System.assertEquals(true,soHelper.checkField('Account','Name',ObjectHelper.ACTION_ACCESS));
      System.assertEquals(true,soHelper.checkField('Account','Name',ObjectHelper.ACTION_UPDATE));
      System.assertEquals(true,soHelper.checkField('Account','Name',ObjectHelper.ACTION_CREATE));
      System.assertEquals(false,soHelper.checkField('Account','Name',ObjectHelper.ACTION_WRITE_READ));
      System.assertEquals(false,soHelper.checkField('Account','Name','thisisnotarealaction'));
      // test field type methods
      System.assertEquals('REFERENCE', soHelper.getFieldType('Account', 'OwnerId'));
      System.assertEquals('ID', soHelper.getFieldSoapType('Account','OwnerId'));
      Map<String, String> acctLookupMap = new Map<String, String> (soHelper.getLookupFieldMap('Account'));
      System.assertEquals(true, acctLookupMap.size()>0);
      
   } 
    //Test GetCreatableFields
   static testMethod void testGetCreatableFields()
   {
       Case testCase = new Case();
       testCase.Status = 'New';
       testCase.Current_Step__c = 'Case Creation';
       testCase.Type = 'ACT';
       testCase.Description = 'TEST CREATABLE FIELDS';
       insert testCase;
       ObjectHelper soHelper = new ObjectHelper();
       string testString = ObjectHelper.getCreatableFields('Case', 'id=\''+testCase.Id +'\'');
       Case createableFields = (Case)Database.query(testString);
       System.assertEquals(true, createableFields.Status == 'New');
       System.assertEquals(true, createableFields.Current_Step__c == 'Case Creation');
       System.assertEquals(true, createableFields.Description == 'TEST CREATABLE FIELDS');
       System.assertEquals(false, createableFields.Description == 'WRONG VALUE');
   }
    // testSObjectField
   static testMethod void testDoObjectsExist() {
      ObjectHelper soHelper = new ObjectHelper();
      // test will null parameter
      Map<String,Boolean> results = soHelper.doObjectsExist(null);
      // verify empty map is returned
      System.assertEquals(0,results.size());

      // object names to test
      String[] objectNames = new String[]{'Account','Lead','BadObjectName1','BadObjectName2','Case'};
      results = soHelper.doObjectsExist(objectNames);
      // verify number of results is correct
      System.assertEquals(5,results.size());
      // check the results
      System.assertEquals(true,results.get(objectNames.get(0)));
      System.assertEquals(true,results.get(objectNames.get(1)));
      System.assertEquals(false,results.get(objectNames.get(2)));
      System.assertEquals(false,results.get(objectNames.get(3)));
      System.assertEquals(true,results.get(objectNames.get(4)));
   } // testDoObjectsExist
   
   // Test getting the label name of a field.
   static testMethod void testGetFieldLabel() {
      ObjectHelper soh = new ObjectHelper();
      System.assertEquals('',soh.getFieldLabel('ThisIsNotAnObject', 'ThisIsNotAField'));
      System.assertEquals('',soh.getFieldLabel('Account', 'ThisIsNotAField'));
      System.assertEquals('Website',soh.getFieldLabel('Account', 'Website'));
   } // testGetFieldLabel
   
   static testMethod void testFieldLength() {
      
      System.assertEquals(0,ObjectHelper.getFieldLngth(null));
      System.assertEquals(255,ObjectHelper.getFieldLngth(Account.Name));
      System.assertEquals(255,ObjectHelper.getFieldLngth(Account.Name));
      
      System.assertEquals(255,new ObjectHelper().getFieldLength('Account','Name'));
   } // testFieldLength

   // Test getting lookup fields on an object.
   static testMethod void testGetLookupFields() {
      ObjectHelper soh = new ObjectHelper();
      Map<String, String> objLookups = soh.getLookupFieldMap('Case');
      System.assertNotEquals(0, objLookups.size());
   } // testGetLookupFields
   
   // Test the methods that return static values.
   static testMethod void testGetStaticMethods() {
      
      System.assertEquals(null,ObjectHelper.getHoldOutFieldName(null,null));
      System.assertEquals(null,ObjectHelper.getHoldOutFieldName(ObjectHelper.OBJECT_ACCOUNT,null));
      System.assertEquals(null,ObjectHelper.getHoldOutFieldName(ObjectHelper.OBJECT_CONTACT,null));
      System.assertEquals(null,ObjectHelper.getHoldOutFieldName(ObjectHelper.OBJECT_LEAD,null));
      System.assertEquals(ObjectHelper.HOLD_OUT,ObjectHelper.getHoldOutFieldName(ObjectHelper.OBJECT_ACCOUNT,UserHelper.SO_CORE));
      System.assertEquals(ObjectHelper.HOLD_OUT,ObjectHelper.getHoldOutFieldName(ObjectHelper.OBJECT_ACCOUNT,UserHelper.SO_MMS));
      System.assertEquals(ObjectHelper.HOLD_OUT_401,ObjectHelper.getHoldOutFieldName(ObjectHelper.OBJECT_ACCOUNT,UserHelper.SO_401));
      System.assertEquals(ObjectHelper.HOLD_OUT_ASO,ObjectHelper.getHoldOutFieldName(ObjectHelper.OBJECT_ACCOUNT,UserHelper.SO_PEO_ASO));
      System.assertEquals(ObjectHelper.HOLD_OUT_HNBF,ObjectHelper.getHoldOutFieldName(ObjectHelper.OBJECT_ACCOUNT,UserHelper.SO_HNB));
      System.assertEquals(ObjectHelper.HOLD_OUT_PEO,ObjectHelper.getHoldOutFieldName(ObjectHelper.OBJECT_ACCOUNT,UserHelper.SO_PEO));
      System.assertEquals(ObjectHelper.HOLD_OUT,ObjectHelper.getHoldOutFieldName(ObjectHelper.OBJECT_CONTACT,UserHelper.SO_CORE));
      System.assertEquals(ObjectHelper.HOLD_OUT,ObjectHelper.getHoldOutFieldName(ObjectHelper.OBJECT_CONTACT,UserHelper.SO_MMS));

      System.assertEquals(ObjectHelper.HOLD_OUT,ObjectHelper.getHoldOutFieldName(ObjectHelper.OBJECT_REF_ACCOUNT,UserHelper.SO_CORE));

      System.assertEquals(null,ObjectHelper.getHoldOutFieldName(ObjectHelper.OBJECT_CONTACT,UserHelper.SO_401));
      System.assertEquals(null,ObjectHelper.getHoldOutFieldName(ObjectHelper.OBJECT_CONTACT,UserHelper.SO_PEO_ASO));
      System.assertEquals(null,ObjectHelper.getHoldOutFieldName(ObjectHelper.OBJECT_CONTACT,UserHelper.SO_HNB));

      System.assertEquals(ObjectHelper.HOLD_OUT,ObjectHelper.getHoldOutFieldName(ObjectHelper.OBJECT_LEAD,UserHelper.SO_CORE));


      System.assertEquals(null,ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_ACCOUNT, null));
      System.assertEquals(null,ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_CONTACT, null));
      System.assertEquals(null,ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_LEAD, null));
      
      System.assertEquals(ObjectHelper.OWNER_FIELD,ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_ACCOUNT, UserHelper.SO_CORE));
      System.assertEquals(ObjectHelper.OWNER_FIELD,ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_ACCOUNT, UserHelper.SO_MMS));
      System.assertEquals(ObjectHelper.OWNER_ACCOUNT_401,ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_ACCOUNT, UserHelper.SO_401));
      System.assertEquals(ObjectHelper.OWNER_ACCOUNT_ASO,ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_ACCOUNT, UserHelper.SO_PEO_ASO));
      System.assertEquals(ObjectHelper.OWNER_ACCOUNT_HNBF,ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_ACCOUNT, UserHelper.SO_HNB));
      System.assertEquals(ObjectHelper.OWNER_ACCOUNT_PEO,ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_ACCOUNT, UserHelper.SO_PEO));
      
      System.assertEquals(ObjectHelper.OWNER_FIELD,ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_CONTACT, UserHelper.SO_CORE));
      System.assertEquals(ObjectHelper.OWNER_FIELD,ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_CONTACT, UserHelper.SO_MMS));
      System.assertEquals(ObjectHelper.OWNER_CONTACT_401,ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_CONTACT, UserHelper.SO_401));
      System.assertEquals(ObjectHelper.OWNER_CONTACT_ASO,ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_CONTACT, UserHelper.SO_PEO_ASO));
      System.assertEquals(ObjectHelper.OWNER_CONTACT_HNBF,ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_CONTACT, UserHelper.SO_HNB));
      System.assertEquals(ObjectHelper.OWNER_CONTACT_PEO,ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_CONTACT, UserHelper.SO_PEO));
      
      System.assertEquals(ObjectHelper.OWNER_FIELD,ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_LEAD, UserHelper.SO_CORE));
      System.assertEquals(ObjectHelper.OWNER_FIELD,ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_LEAD, UserHelper.SO_MMS));
      System.assertEquals(null,ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_LEAD, UserHelper.SO_401));
      System.assertEquals(null,ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_LEAD, UserHelper.SO_PEO_ASO));
      System.assertEquals(null,ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_LEAD, UserHelper.SO_HNB));

      //System.assertEquals(ObjectHelper.OWNER_CONTACT_WHOLE_EXT,ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_REF_CONTACT, UserHelper.SO_WHOLESALER,UserHelper.WHOLESALER_EXTERNAL));
      System.assertEquals(ObjectHelper.OWNER_CONTACT_WHOLE_INT,ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_REF_CONTACT, UserHelper.SO_WHOLESALER,UserHelper.WHOLESALER_INTERNAL));
      System.assertEquals(ObjectHelper.OWNER_CONTACT_MMS,ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_REF_CONTACT, UserHelper.SO_MMS,null));
   
      System.assertEquals('MMS_Account_Owner__c',ObjectHelper.getOwnerFieldName(ObjectHelper.OBJECT_REF_ACCOUNT, UserHelper.SO_MMS));
   } // testGetStaticMethods
   
   static testMethod void testObjectPrefix() {
    System.assertEquals('003',ObjectHelper.getObjectPrefix('Contact'));
      System.assertEquals('006',ObjectHelper.getObjectPrefix('Opportunity'));
      System.assertEquals(null,ObjectHelper.getObjectPrefix('ThisIsNotAnObject'));
   } // testObjectPrefix

   static testMethod void testGetSOQLQuery() {
    System.assertEquals(null,ObjectHelper.getSOQLQuery('BadName', null, false, false));
    String query = ObjectHelper.getSOQLQuery('Account', null, false, false);
    System.assertEquals(true,query.contains('Name'));
    String[] extraFlds = new String[]{'Account.Name','Account.AccountNumber'};
    query = ObjectHelper.getSOQLQuery('Contact', extraFlds, true, true);
    System.assertEquals(true,query.contains('AccountId'));
      System.assertEquals(true,query.contains('Account.Name'));
   } // testGetSOQLQuery
   
   static testMethod void testGetObjectName() {
      System.assertEquals(null,ObjectHelper.getObjectName(null));
      System.assertEquals(ObjectHelper.OBJECT_ACCOUNT,ObjectHelper.getObjectName(new Account()));
      System.assertEquals(ObjectHelper.OBJECT_CONTACT,ObjectHelper.getObjectName(new Contact()));
      System.assertEquals(ObjectHelper.OBJECT_LEAD,ObjectHelper.getObjectName(new Lead()));
      System.assertEquals(ObjectHelper.OBJECT_OPPTY,ObjectHelper.getObjectName(new Opportunity()));
      System.assertEquals(ObjectHelper.OBJECT_REF_ACCOUNT,ObjectHelper.getObjectName(new Referral_Account__c()));
      System.assertEquals(ObjectHelper.OBJECT_REF_CONTACT,ObjectHelper.getObjectName(new Referral_Contact__c()));
      
   } // testGetObjectName
   
   static testMethod void testFieldNameMethods() {
      System.assertEquals(null,ObjectHelper.getEmpCntFieldName(null));
      System.assertEquals(null,ObjectHelper.getEmpCntFieldName('Bad Object Name'));
      System.assertEquals(ObjectHelper.FIELD_NUMBER_EMPS,ObjectHelper.getEmpCntFieldName(ObjectHelper.OBJECT_ACCOUNT));
      System.assertEquals(ObjectHelper.FIELD_NUMBER_EMPS,ObjectHelper.getEmpCntFieldName(ObjectHelper.OBJECT_LEAD));

      System.assertEquals(null,ObjectHelper.getAssetFieldName(null));
      System.assertEquals(null,ObjectHelper.getAssetFieldName('Bad Object Name'));
      System.assertEquals(ObjectHelper.FIELD_ASSET,ObjectHelper.getAssetFieldName(ObjectHelper.OBJECT_ACCOUNT));
      System.assertEquals(ObjectHelper.FIELD_ASSET,ObjectHelper.getAssetFieldName(ObjectHelper.OBJECT_LEAD));
   } // testFieldNameMethods

   static testMethod void testFormatStringAsObject() {
      Map<String, Schema.SObjectField> fieldMap = new ObjectHelper().getFieldMap(ObjectHelper.OBJECT_ACCOUNT);
      // User_Owned_Shipping_Address__c - for boolean
      Object value1 = ObjectHelper.formatStringAsObject(fieldMap.get('User_Owned_Shipping_Address__c'),'true');
      // Lost_Date__c - date
      Object value2 = ObjectHelper.formatStringAsObject(fieldMap.get('Lost_Date__c'),'7/1/1977');
      // AnnualRevenue - currency
      Object value3 = ObjectHelper.formatStringAsObject(fieldMap.get('AnnualRevenue'),'$123.45');
      //  double, percent
      // NumberOfEmployees - integer
      Object value4 = ObjectHelper.formatStringAsObject(fieldMap.get('NumberOfEmployees'),'7');
      // Phone
      Object value5 = ObjectHelper.formatStringAsObject(fieldMap.get('Phone'),'5551234567');
      // Name
      Object value6 = ObjectHelper.formatStringAsObject(fieldMap.get('Name'),'"This is a test Name"');
      // PayOppCreatedDate__c - DateTime
      Object value7 = ObjectHelper.formatStringAsObject(fieldMap.get('PayOppCreatedDate__c'),'1989-12-13 8:36:14');
       
      Object value8a = ObjectHelper.formatStringAsObject(fieldMap.get('AnnualRevenue'),'-123.45');
      Double checkVal8a = Double.valueOf(value8a);
      System.assertEquals(-123.45,checkVal8a);
      
      
      Account acct = new Account();
      acct.put('User_Owned_Shipping_Address__c',value1);
      acct.put('Lost_Date__c',value2);
      acct.put('AnnualRevenue',value3);
      acct.put('NumberOfEmployees',value4);
      acct.put('Phone',value5);
      acct.put('Name',value6);
      acct.put('PayOppCreatedDate__c',value7);
      
      ZipCheckOwner.SKIP_TRIGGERS = true;
      insert acct;
      
      acct = [Select Id, Name, Phone, NumberOfEmployees, AnnualRevenue, Lost_Date__c, User_Owned_Shipping_Address__c, PayOppCreatedDate__c from Account where Id=:acct.Id];
      System.assertEquals('This is a test Name',acct.Name);
      System.assertEquals('(555) 123-4567', acct.Phone);
      System.assertEquals(7,acct.NumberOfEmployees);
      System.assertEquals(123.45,acct.AnnualRevenue);
      System.assertEquals(true,acct.User_Owned_Shipping_Address__c);
      System.assertEquals(Date.newInstance(1977,7,1),acct.Lost_Date__c);
      System.assertEquals(DateTime.newInstance(1989,12,13,8,36,14),acct.PayOppCreatedDate__c);
      
      Object value8 = ObjectHelper.formatStringAsObject(fieldMap.get('Lost_Date__c'),'BadDate');
      System.assertEquals(null,value8);
      value8 = ObjectHelper.formatStringAsObject(fieldMap.get('NumberOfEmployees'),'BadNumber');
      System.assertEquals(null,value8);
      
      Object value9 = ObjectHelper.formatStringAsObject(fieldMap.get('Lost_Date__c'),'1977-7-1');
      System.assertEquals(true, value9 != null);
      System.assertEquals(Date.newInstance(1977,7,1),(Date)value9);
       
      fieldMap = new ObjectHelper().getFieldMap(ObjectHelper.OBJECT_CONTACT);
      Object value10 = ObjectHelper.formatStringAsObject(fieldMap.get('Email'),'-');
      System.assertEquals(null,value10);
      value10 = ObjectHelper.formatStringAsObject(fieldMap.get('Email'),'ThisIsABadEmail');
      System.assertEquals(null,value10);
      value10 = ObjectHelper.formatStringAsObject(fieldMap.get('Email'),'ThisIs@BadEmail');
      System.assertEquals(null,value10);
      value10 = ObjectHelper.formatStringAsObject(fieldMap.get('Email'),'dcarmen@paychex.com');
      System.assertEquals('dcarmen@paychex.com',(String)value10);
      value10 = ObjectHelper.formatStringAsObject(fieldMap.get('Email'),'ThisIs@GoodEmail.com');
      System.assertNotEquals(null,value10);

   } // testFormatStringAsObject
   
   static testMethod void testGetNameFromId() {
      Account acct = new Account(Name='Test Acct');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
       
      Contact ctct = new Contact(LastName='Test', AccountId=acct.Id);
      insert ctct;
      
      String objectName = ObjectHelper.getObjectNameFromId(acct.Id);
      System.assertEquals(ObjectHelper.OBJECT_ACCOUNT, objectName);

      String objectLabel = ObjectHelper.getObjectLabelFromId(ctct.Id);
      System.assertEquals(ObjectHelper.OBJECT_CONTACT, objectLabel);
} // testGetNameFromId
   
} // class ObjectHelperTest