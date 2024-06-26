/* 
 * Test methods for the ZipCodeLookupController
 *
 * History
 * -------
 * 05/24/2012 Dan Carmen        Created.
   06/29/2012 Dan Carmen        Change so DSM/DSA only displayed if User is a sales rep.
   07/11/2012 Dan Carmen        Added more logic to be able to manually load DSMs/DSAs
   07/25/2012 Dan Carmen        Added in check for sales org when selected DSM/DSA.
   07/07/2020 Dan Carmen        Slight change to the getZipAssignment method for SOAR.

*/
@isTest
private class ZipCodeLookupControllerTest {

   static testMethod void testNoZip() {
      // set the page reference
      Test.setCurrentPage(Page.ZipCodeLookup);
      
      // create segments
      Zip_Segment__c[] segments = createSegments();
      ZipCodeLookupController zclc = new ZipCodeLookupController();
      // there is now segmentation data - no error should occur here
      System.assertEquals(false,ApexPages.hasMessages() );

      // perform a query with no data
      zclc.zipCodeQuery = null;
      System.assertEquals(null,zclc.queryZipCodes());
      System.assertEquals(true,ApexPages.hasMessages() );
      // get the message
      ApexPages.Message msg = ApexPages.getMessages().get(0);
      System.assertEquals('A valid 5 character zip code must be entered!',msg.getDetail());
      System.assertEquals(ApexPages.severity.ERROR,msg.getSeverity());
   } // testNoZip
   
   static testMethod void testBadZip() {
      // set the page reference
      Test.setCurrentPage(Page.ZipCodeLookup);
      
      // create segments
      Zip_Segment__c[] segments = createSegments();
      ZipCodeLookupController zclc = new ZipCodeLookupController();
      // there is now segmentation data - no error should occur here
      System.assertEquals(false,ApexPages.hasMessages() );

      // perform a query with a 6 character zip code
      zclc.zipCodeQuery = '123456';
      System.assertEquals(null,zclc.queryZipCodes());
      System.assertEquals(true,ApexPages.hasMessages() );
      // get the message
      ApexPages.Message msg = ApexPages.getMessages().get(0);
      System.assertEquals('A valid 5 character zip code must be entered!',msg.getDetail());
      System.assertEquals(ApexPages.severity.ERROR,msg.getSeverity());
   } // testBadZip
   
   /** Create some default segments. */
   private static Zip_Segment__c[] createSegments() {
      Zip_Segment__c[] segments = new Zip_Segment__c[]{};
      segments.add(new Zip_Segment__c(Name='Test Core',Sales_Org__c=UserHelper.SO_CORE,Emps_Min__c=0,Emps_Max__c=999999,Paychex_Id__c='TestCore'));
      segments.add(new Zip_Segment__c(Name='Test MMS',Sales_Org__c=UserHelper.SO_MMS,Emps_Min__c=0,Emps_Max__c=999999,Paychex_Id__c='TestMms'));
      segments.add(new Zip_Segment__c(Name='Test HNB1',Sales_Org__c=UserHelper.SO_HNB,Emps_Min__c=0,Emps_Max__c=49,Paychex_Id__c='TestHnb1'));
      segments.add(new Zip_Segment__c(Name='Test HNB2',Sales_Org__c=UserHelper.SO_HNB,Emps_Min__c=50,Emps_Max__c=999999,Paychex_Id__c='TestHnb2'));
      insert segments;
      return segments;
   } // createSegments
   
   /** Create a Zip_Code_Information__c record. */
   private static Zip_Code_Information__c createZci(String zipCode) {
   	Zip_Code_Information__c zci = new Zip_Code_Information__c(Name=zipCode,Zip_Code_Key__c=zipCode,City__c='Test City',State__c='NY');
   	insert zci;
   	return zci;
   } // create Zci
   
   /** Create Zip_Assignment__c records.
    */
   private static Zip_Assignment__c[] createZipAsgns(String zipCode, Zip_Segment__c[] segments) {
      Map<String, Org_Unit__c> districtMap = new Map<String, Org_Unit__c>();
      Map<Id, Zip_Segment__c> segmentMap = new Map<Id, Zip_Segment__c>();
      
      for (Zip_Segment__c segment : segments) {
      	segmentMap.put(segment.Id, segment);
      	if (!districtMap.containsKey(segment.Sales_Org__c)) {
            Org_Unit__c district = new Org_Unit__c(Name='1', Org_Unit_Name__c='Test '+segment.Sales_Org__c
                                  ,Sales_Org__c=segment.Sales_Org__c, Org_Type__c=OrgUnitMethods.TYPE_DISTRICT
                                  ,MgrName__c='Joe Manager', MgrEmail__c='joe.manager.@test.com'
                                  ,AssistantName__c='Jimmy Assistant', AssistantEmail__c='jimmy.assistant@test.com'
                                  ,OverrideMgr__c=true,OverrideAssistant__c=true );
            //districts.add(district);
            districtMap.put(segment.Sales_Org__c, district);
      	}
      } // for
      insert districtMap.values();
      
      // select a rep for each segment - we won't care about sales orgs
      User[] reps = [Select Id, Name
                       From User
                      Where IsActive = true
                        And Profile.Name in :Utilities.REP_PROFS
                      limit :segments.size()];
      // select a DSA and DSM
      User dsa = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_DSA limit 1];
      User dsm = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_DSM limit 1];
      
      // create a dsm and dsa link for each district
      Org_Unit_User_Link__c[] links = new Org_Unit_User_Link__c[]{};
      for (Org_Unit__c district : districtMap.values()) {
         Org_Unit_User_Link__c dsaLink = new Org_Unit_User_Link__c(Org_Unit__c=district.Id, User__c=dsa.Id);
         Org_Unit_User_Link__c dsmLink = new Org_Unit_User_Link__c(Org_Unit__c=district.Id, User__c=dsm.Id);
         links.add(dsaLink);
         links.add(dsmLink);
      } // for (Org_Unit__c district
      insert links;
      
      // create territories - 1 for each segment
      ZipTerritory__c[] territories = new ZipTerritory__c[]{};
      for (Zip_Segment__c segment : segments) {
         Org_Unit__c district = districtMap.get(segment.Sales_Org__c);
         User rep = reps.remove(reps.size()-1);
         ZipTerritory__c territory = new ZipTerritory__c(Name='Territory 1',District__c=district.Id
                                    ,Rep_Name__c=rep.Name, Territory_Nbr__c='1'
                                    ,TerritoryRep__c=rep.Id
                                    ,Zip_Segment__c=segment.Id);
         territories.add(territory);
      } // for (Zip_Segment__c segment
      insert territories;
      
      // create the zip assignments
      Zip_Assignment__c[] zipAssigns = new Zip_Assignment__c[]{};
      
      for (ZipTerritory__c territory : territories) {
      	Zip_Segment__c segment = segmentMap.get(territory.Zip_Segment__c);
         Zip_Assignment__c za = new Zip_Assignment__c(Name=zipCode, Emps_Max__c=segment.Emps_Max__c, Emps_Min__c=segment.Emps_Min__c);
         za.BypassDistrictTrigger__c = true;
         za.Rep_Name__c = territory.Rep_Name__c;
         za.User__c = territory.TerritoryRep__c;
         za.Zip_Segment__c = territory.Zip_Segment__c;
         za.ZipTerritory__c = territory.Id;
         za.District__c = territory.District__c;
         za.Sales_Org__c = segment.Sales_Org__c;
         zipAssigns.add(za);
      } // for (ZipTerritory__c territory
      insert zipAssigns;
      
      return zipAssigns;
   } // createZipAsgns

      
   /** Test a normal procedure. */
   static testMethod void testZips() {
      // set the page reference
      Test.setCurrentPage(Page.ZipCodeLookup);
      
      // create segments
      Zip_Segment__c[] segments = createSegments();
      ZipCodeLookupController zclc = new ZipCodeLookupController();
      // check default values
      System.assertEquals(null,zclc.zipCodeQuery);
      System.assertEquals(null,zclc.zipInfo);
      System.assertEquals(false,zclc.displayFAQ);
      System.assertEquals(false,zclc.hasZipInfo);
      System.assertEquals('Display FAQ',zclc.faqLinkTitle);
      System.assertEquals(false,zclc.hasResults);
      
      // query with a zip code that does not exist in the tables
      // perform a query with a 5 character zip code
      zclc.zipCodeQuery = '12345';
      System.assertEquals(null,zclc.queryZipCodes());
      // should be no errors
      System.assertEquals(false,ApexPages.hasMessages() );
      // still no zipInfo
      System.assertEquals(false,zclc.hasZipInfo);
      // has no results - only returns rows that have a zip_assignment record.
      System.assertEquals(false,zclc.hasResults);
      // no results were returned
      System.assertEquals(0,zclc.zipResults.size());
      
      // query with the zip info and zip assignment records
      Zip_Code_Information__c zci = createZci('12345');
      Zip_Assignment__c[] zipAsgns = createZipAsgns('12345', segments);

      zclc.zipCodeQuery = '12345';
      System.assertEquals(null,zclc.queryZipCodes());
      // should be no errors
      System.assertEquals(false,ApexPages.hasMessages() );
      // still no zipInfo
      System.assertEquals(true,zclc.hasZipInfo);
      // has results because of the zip segments
      System.assertEquals(true,zclc.hasResults);
      // number of results should equal the number of segments
      System.assertEquals(segments.size(),zclc.zipResults.size());
      // verify the showAllColumns flag
      System.assertEquals(false,zclc.showAllColumns);
      // toggle the flag
      System.assertEquals(null,zclc.toggleShowAllColumns());
      // verify the showAllColumns is now true;
      System.assertEquals(true,zclc.showAllColumns);
      
   } // testZips
   
   static testMethod void testOther() {
      ZipCodeLookupController zclc = new ZipCodeLookupController();
      System.assertEquals(false,zclc.displayFAQ);
      System.assertEquals(null,zclc.toggleFAQ());
      System.assertEquals(true,zclc.displayFAQ);
      System.assertEquals(null,zclc.toggleFAQ());
      System.assertEquals(false,zclc.displayFAQ);
      System.assertEquals(null,zclc.toggleFAQ());
      System.assertEquals(true,zclc.displayFAQ);
      
   } // testOther

   static testMethod void testGetZipAssignment() {
      Zip_Segment__c[] segments = createSegments();
      // query with the zip info and zip assignment records
      Zip_Code_Information__c zci = createZci('12345');
      Zip_Assignment__c[] zipAsgns = createZipAsgns('12345', segments);

      ZipCheckOwner.setupRecordTypeMaps();
      Id recordTypeId = ZipCheckOwner.rtByName.get(RecordTypeHelper.CORE_ACCOUNT).getRecordTypeId();
      Account acct = new Account(Name='Test Account', RecordTypeId=recordTypeId, ShippingPostalCode='12345',NumberOfEmployees=30);
      
      ZipWrapper wrapper = ZipCodeLookupController.getZipAssignment('12345', UserHelper.SO_CORE, acct);
      System.assertEquals(UserHelper.SO_CORE, wrapper.za.Sales_Org__c);
   } // testGetZipAssignment
   
} // class ZipCodeLookupControllerTest