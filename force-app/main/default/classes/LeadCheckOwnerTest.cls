/* 
   Test methods for the LeadCheckOwner trigger and class.
   
  History
  -------
  01/28/2011 Dan Carmen   Created
  08/22/2011 Dan Carmen   Added check for records created via Jigsaw
  06/01/2012 Dan Carmen   Changes for Zip_Assignment__c object
  06/12/2012 Cindy Freeman  Added test for LeadSource validatino from RJDB
  06/12/2014 Dan Carmen   Changes to handle the lead hold out field
  11/18/2015 Dan Carmen   Changed to use a custom setting for recordtype mapping.
  06/11/2018 Cindy Freeman  added test for PEO Centric segment
  03/27/2019 Jake Hinds    changes for peo c
  06/06/2019 Dan Carmen    Increment API version
  03/29/2021 Karthik Pedditi	Update City and State based on ZIPCODE
  01/07/2022 Dan Carmen    Remove references to PeoHelper code
  01/10/2021 Pujitha Madamanchi APR0129320 Removed LeadState code - moved to TrackRecordEntry 
  05/10/2022 Dan Carmen    Update ownership code     
  10/22/2023 Dan Carmen    Update criteria check
  01/02/2024 Dan Carmen    Additional linkage for ZipSegmentCriteriaLink__c for more flexibility

 */
@isTest
public class LeadCheckOwnerTest {

   @testSetup
   public static void setupSettings() {
      ProductGroupMapping__c[] mappings = new ProductGroupMapping__c[]{};
      mappings.add(new ProductGroupMapping__c(Name='LeadMap-MMS',MappingType__c='LeadMap',Product_of_Interest__c='MMS'
                                             ,RecordTypeName__c=Label.RT_MMS_Lead,Sales_Org__c='MMS'));
      mappings.add(new ProductGroupMapping__c(Name='LeadMap-Agency',MappingType__c='LeadMap',Product_of_Interest__c='Agency'
                                             ,RecordTypeName__c=Label.RT_HNBF_Lead,Sales_Org__c='HNBF'));
      mappings.add(new ProductGroupMapping__c(Name='LeadMap-FA',MappingType__c='LeadMap',Product_of_Interest__c='FA'
                                             ,RecordTypeName__c=Label.RT_HRS_Lead,Sales_Org__c='HRS'));
      mappings.add(new ProductGroupMapping__c(Name='LeadMap-HRS',MappingType__c='LeadMap',Product_of_Interest__c='HRS'
                                             ,RecordTypeName__c=Label.RT_HRS_Lead,Sales_Org__c='HRS'));
      mappings.add(new ProductGroupMapping__c(Name='LeadMap-Leasing/PEO',MappingType__c='LeadMap',Product_of_Interest__c='Leasing/PEO'
                                             ,RecordTypeName__c=Label.RT_PEO_ASO_Lead,Sales_Org__c='PEO'));
      mappings.add(new ProductGroupMapping__c(Name='LeadMap-MSP',MappingType__c='LeadMap',Product_of_Interest__c='MSP'
                                             ,RecordTypeName__c='MSP Lead Record Type',Sales_Org__c='MSP'));
      mappings.add(new ProductGroupMapping__c(Name='LeadMap-PEOCentric',MappingType__c='LeadMap',Product_of_Interest__c='PEOCentric'
                                             ,RecordTypeName__c=Label.RT_PEO_Lead,Sales_Org__c='PEO'));
      mappings.add(new ProductGroupMapping__c(Name='LeadMap-HNBF',MappingType__c='LeadMap',Product_of_Interest__c='HNBF'
                                             ,RecordTypeName__c=Label.RT_HNBF_Lead,Sales_Org__c='HNBF'));
      insert mappings;
      
      // set the running user as lead loader.
   } // setupSettings

   static testMethod void testAllLeads() {
      User runningUser = UserHelper.getRunningUser();
      ProcessNameMap__c pnm1 = UserHelperTest.setupProcessName(UserHelper.PREFIX_LL,runningUser.Name);
      ProcessNameMap__c pnm2 = UserHelperTest.setupProcessName(UserHelper.PREFIX_LL,UserHelper.LEAD_LOADER);

      //setupSettings();
     Id[] excludeUserIds = new Id[]{};
     // get zip codes
     Map<String,List<Zip_Assignment__c>> zaMapList1 = ZipCheckOwnerTest.getZaMapList('12345',excludeUserIds);
      //Map<String,List<Zip_Assignment__c>> zaMapList2 = ZipCheckOwnerTest.getZaMapList('98765',excludeUserIds);

      User uCore1 = zaMapList1.get(UserHelper.SO_CORE).get(0).User__r;
      User uMms1 = zaMapList1.get(UserHelper.SO_MMS).get(0).User__r;
      User uHrs1 = zaMapList1.get(UserHelper.SO_401).get(0).User__r;
      User uPeo1 = zaMapList1.get(UserHelper.SO_PEO_ASO).get(0).User__r;
      User uPeo2 = zaMapList1.get(UserHelper.SO_PEO_ASO).get(1).User__r;
      User uPeoC = zaMapList1.get(UserHelper.SO_PEO).get(0).User__r;
      User uHnb1 = zaMapList1.get(UserHelper.SO_HNB).get(0).User__r;
      //NSS_Zip_Assignment__c nza2 = getNza('2',users);
      //nza2.Core__c = null;
      //nza2.MMS_Sales_Rep_Person_ID__c = null;
      //nza2.HRS_Sales_Rep_Person_ID__c = null;
      //update nza2;
      
      // run as the Marketo user - will assume user is always here.
      //User usr = [Select Id, Name from User where IsActive=true and Name=:UserHelper.MARKETO];
      User usr = [Select Id, Name from User where IsActive=true and Name=:UserHelper.LEAD_LOADER limit 1];
      
      System.runAs(usr) {
         Lead l1 = new Lead(LastName='Test1',Company='Test1 Co',Product_Division__c='MMS',NumberOfEmployees=60, PostalCode='12345');
         Lead l2 = new Lead(LastName='Test2',Company='Test2 Co',Product_Division__c='Agency',NumberOfEmployees=null, PostalCode='12345');
         Lead l3 = new Lead(LastName='Test3',Company='Test3 Co',Product_Division__c='CPA',NumberOfEmployees=60, PostalCode='12345');
         Lead l4 = new Lead(LastName='Test4',Company='Test4 Co',Product_Division__c='Bank',NumberOfEmployees=60, PostalCode='12345');
         Lead l5 = new Lead(LastName='Test5',Company='Test5 Co',Product_Division__c='FA',NumberOfEmployees=60, PostalCode='12345');
         Lead l6 = new Lead(LastName='Test6',Company='Test6 Co',Product_Division__c='HRS',NumberOfEmployees=60, PostalCode='12345');
         //Lead l7 = new Lead(LastName='Test7',Company='Test7 Co',Product_Division__c='Leasing/PEO',NumberOfEmployees=60, PostalCode='12345');
         Lead l7 = new Lead(LastName='Test7',Company='Test7 Co',Product_Division__c='PEOCentric',NumberOfEmployees=60, PostalCode='12345');
         Lead l8 = new Lead(LastName='Test8',Company='Test8 Co',Product_Division__c=null,NumberOfEmployees=60, PostalCode='12345');
         Lead l9 = new Lead(LastName='Test9',Company='Test9 Co',Product_Division__c=null,NumberOfEmployees=9, PostalCode='12345');

         Lead l10 = new Lead(LastName='Test10',Company='Test10 Co',Product_Division__c='Core',NumberOfEmployees=30, PostalCode='98765');
         Lead l11 = new Lead(LastName='Test11',Company='Test11 Co',Product_Division__c='MMS',NumberOfEmployees=60, PostalCode='98765');
         Lead l12 = new Lead(LastName='Test12',Company='Test12 Co',Product_Division__c='HRS',NumberOfEmployees=60, PostalCode='98765');
         // test to make sure the lead record type doesn't change
         Lead l13 = new Lead(LastName='Test13',Company='Test13 Co',Product_Division__c='Core',NumberOfEmployees=30, PostalCode='12345',OwnedByPrev__c=Label.LeadRouting_Weblead);

         Lead[] leads = new Lead[]{l1,l2,l3,l4,l5,l6,l7,l8,l9,l10,l11,l12,l13};
         insert leads;
         Id[] leadIds = new Id[]{l1.Id,l2.Id,l3.Id,l4.Id,l5.Id,l6.Id,l7.Id,l8.Id,l9.Id,l10.Id,l11.Id,l12.Id,l13.Id};
         Map<Id,Lead> leadCheck = new Map<Id,Lead>([Select Id, OwnerId, RecordType.Name from Lead where Id in :leadIds]);
         
         System.assertEquals(uMms1.Id,leadCheck.get(l1.Id).OwnerId);
         System.assertEquals(uHnb1.Id,leadCheck.get(l2.Id).OwnerId);
         System.assertEquals(uCore1.Id,leadCheck.get(l3.Id).OwnerId);
         System.assertEquals(uCore1.Id,leadCheck.get(l4.Id).OwnerId);
         System.assertEquals(uHrs1.Id,leadCheck.get(l5.Id).OwnerId);
         System.assertEquals(uHrs1.Id,leadCheck.get(l6.Id).OwnerId);
         //System.assertEquals(uHrs1.Id,leadCheck.get(l7.Id).OwnerId);
         System.assertEquals(uPeoC.Id,leadCheck.get(l7.Id).OwnerId);         
         System.assertEquals(uMms1.Id,leadCheck.get(l8.Id).OwnerId);
         System.assertEquals(uCore1.Id,leadCheck.get(l9.Id).OwnerId);
         
         // get the group id
         //Group marketGrp = new UserHelper().getQueue(LeadCheckOwner.QUEUE_NAME);
         // this should exist, but verify to make sure
         //System.assertEquals(true,(marketGrp != null));
         
         // the last three should all be assigned to the queue
         //System.assertEquals(marketGrp.Id,leadCheck.get(l10.Id).OwnerId);
         //System.assertEquals(marketGrp.Id,leadCheck.get(l11.Id).OwnerId);
         //System.assertEquals(marketGrp.Id,leadCheck.get(l12.Id).OwnerId);
         // make sure the lead doesn't change
         //System.assertEquals(usr.Id, leadCheck.get(l13.Id).OwnerId);
         //System.assertEquals(UserInfo.getUserId(), leadCheck.get(l13.Id).OwnerId);
         //System.assertEquals(Label.RT_NSS_Lead, leadCheck.get(l13.Id).RecordType.Name);
      } // System.runAs
   } // testAllLeads

   static testMethod void testGetGroup() {
      // test retrieving a group that does not exist
      System.assertEquals(null,new UserHelper().getQueue('This group does not exist'));
      
   } // testGetGroup
   

} // class LeadCheckOwnerTest