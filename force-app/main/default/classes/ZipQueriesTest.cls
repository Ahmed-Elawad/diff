/* Test Methods for ZipQueries class
   
  History
  -------
  06/19/2018 Dan Carmen         Created
  04/29/2020 Dan Carmen         Change Zip Segment query to use a fieldSet.
  08/25/2021 Dan Carmen         Add Job_Name__c field to the user query, add more tests
  03/25/2022 Dan Carmen         Updates for Referral Account ownership
  06/19/2023 Dan Carmen         Update getZipUserMap to use fieldsets
  10/06/2023 Dan Carmen         Update getAllSegments query
  
 */
@isTest
public class ZipQueriesTest {
    
    @testSetup
    public static void setupData() {
        ZipSegmentCriteria__c criteria1 = new ZipSegmentCriteria__c(Name='Test1',Account__c=true, Lead__c=true, ReferralAccount__c=false, FieldAPIName__c='Hispanic_Ownership__c');
        ZipSegmentCriteria__c criteria2 = new ZipSegmentCriteria__c(Name='Test2',Account__c=false, Lead__c=false, ReferralAccount__c=true, FieldAPIName__c='Broker_Branch__c');
        insert new ZipSegmentCriteria__c[]{criteria1,criteria2};
    } // setupData

    static testMethod void testSegmentQueries() {
       // create the zip segments
       ZipCheckOwnerTest.setupSegments();
       // just retrieve a subset
       String[] salesOrgs = new String[]{UserHelper.SO_CORE,UserHelper.SO_MMS};
       Zip_Segment__c[] segments = ZipQueries.getSegments(salesOrgs);
       System.assertEquals(5,segments.size());
       System.assertEquals(true,ZipQueries.queryPerformed);
       
       // reset the flag.
       ZipQueries.queryPerformed = false;
       
       Map<Id,Zip_Segment__c> segmentMap = ZipQueries.getSegmentMap(null);
       System.assertEquals(ZipCheckOwnerTest.segments.size(), segmentMap.size());
       System.assertEquals(true, segmentMap.containsKey(ZipCheckOwnerTest.hrsSeg1.Id));
       // make sure the cache is working
       System.assertEquals(false,ZipQueries.queryPerformed);
       
    } // testSegmentQueries
    
   static testMethod void testCheckDefaultZips() {
      System.assertEquals(null,ZipQueries.defCoreZip);
      System.assertEquals(null,ZipQueries.defMMSZip);
      ZipQueries.checkDefaultZips();
      System.assertNotEquals(null,ZipQueries.defCoreZip);
      System.assertNotEquals(null,ZipQueries.defMMSZip);
       
      // test with an empty set
      Map<Id,User> userMap = ZipQueries.getZipUserMap(new Set<Id>());
      System.assertEquals(true,userMap.isEmpty());
   } // testCheckDefaultZips
    
   static testMethod void testGetZipMap() {
       Map<String,List<Zip_Assignment__c>> zaMap = ZipCheckOwnerTest.getZaMapList('90210',new Id[]{});
       Set<String> zipSet = new Set<String>();
       zipSet.add('90210');
       Map<String,List<Zip_Assignment__c>> zipAsgnMap = ZipQueries.getZipAsgnMap(zipSet, true);
       Zip_Assignment__c[] zips = zipAsgnMap.get('90210');
       System.assertEquals(false,zips.isEmpty());
   } // testGetZipMap
    
   static testMethod void testMisc() {
      Set<String> fldSet = ZipQueries.getAccountQueryFields();
      System.assertEquals(true,fldSet.contains('Hispanic_Ownership__c'));
      fldSet = ZipQueries.getLeadQueryFields();
      System.assertEquals(true,fldSet.contains('Hispanic_Ownership__c'));
      fldSet = ZipQueries.getRefAcctQueryFields();
      System.assertEquals(true,fldSet.contains('Broker_Branch__c'));
   }
    
} // class ZipQueriesTest