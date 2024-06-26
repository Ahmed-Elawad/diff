/* 
 * Test methods for the ZipAssignment class
 *
 * History
 * -------
 * 04/24/2012 Dan Carmen   Created
   06/06/2012 Dan Carmen   Added logic to ensure Zip_Code_Information__c is linked to Zip_Assignment__c.
   06/20/2012 Dan Carmen   Added new criteria for checking the User.
   11/21/2012 Dan Carmen   Changed to use person id for Unassigned users
   12/12/2012 Dan Carmen   Added asset criteria
   03/28/2013 Dan Carmen   Added additional changes for wholesalers
   10/22/2014 Dan Carmen   Cleaned up code due to NSS coming into Salesforce
   08/11/2015 Dan Carmen   Adjust test to be case insensitive for county name.
   02/08/2016 Dan Carmen   Clean up checkUseCriteria
   07/24/2018 Dan Carmen   Update so a test will pass.
   06/21/2019 Dan Carmen   Update how criteria is evaluated.
   03/30/2020 Dan Carmen   Move logic from trigger to here. Change how segment coverage is handled. 
   05/25/2021 Dan Carmen   Increment the API version
   03/25/2022 Dan Carmen   Populate the RecordType Ids on the Zip Segment
   05/10/2022 Dan Carmen   Check for delete of Zip Segment
   09/27/2023 Dan Carmen   Remove recursion check, clean up code.
   11/30/2023 Dan Carmen   Removed unused fields on Zip Assignment/Zip Territory
   02/08/2024 Dan Carmen   Try to force the change record creation
   03/04/2024 Dan Carmen   Updated checkZipCodeLength method

 */
@isTest
public class ZipAssignmentTest {
    @testSetup
    public static void setupData() {
      ZipCheckOwnerTest.setupSegments();

    } // setupData

 
   static testMethod void testNewRecord() {
    UserHelperTest.setupSalesOrgSetting();
    
    // so the trigger fires.
      User runningUser = UserHelper.getRunningUser();
      ZipCheckOwnerTest.setupSegments();

      // test creating new Zip_Assignment__c records
      // select test users
      User[] users = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 7];
      User uCore = users[0]; //[Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE limit 1];
      User uCore2 = users[1]; //[Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Id != :uCore.Id limit 1];
      User uCore3 = users[2]; //[Select Id, FirstName, LastName, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Id != :uCore.Id and Id != :uCore2.Id limit 1];
      User uMms = users[3]; //[Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_MMS limit 1];
      User uHrs = users[4]; //[Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_401 limit 1];
      User uPeo = users[5]; //[Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_PEO_ASO limit 1];
      User uHnb = users[6]; //[Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_HNB limit 1];
      
      // make sure there are no change records
      System.assertEquals(0,[Select count() from Zip_Assignment_Change__c]);
      
      // verify the unassigned users exist
      User unassignedCore = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where IsActive=true and HR_Person_Id__c=:UserHelper.UNASSIGNED_CORE_PERSON_ID limit 1];
      User unassignedMMS = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where IsActive=true and HR_Person_Id__c=:UserHelper.UNASSIGNED_MMS_PERSON_ID limit 1];
      
      // create Zip Assignment records
      Zip_Assignment__c[] zas = new Zip_Assignment__c[]{};
      
      Zip_Assignment__c za1 = ZipCheckOwnerTest.createZa('14514', uCore, UserHelper.SO_CORE, ZipCheckOwnerTest.coreSeg1.Name, ZipCheckOwnerTest.coreSeg1.Id, null, null, zas);

      Zip_Assignment__c za2 = ZipCheckOwnerTest.createZa('14515', uCore, UserHelper.SO_CORE, ZipCheckOwnerTest.coreSeg1.Name, ZipCheckOwnerTest.coreSeg1.Id, null, null, zas);

      Zip_Assignment__c za3 = ZipCheckOwnerTest.createZa('14514', uMms, UserHelper.SO_MMS, ZipCheckOwnerTest.mmsSeg1.Name, ZipCheckOwnerTest.mmsSeg1.Id, null, null, zas);

      Zip_Assignment__c za4 = ZipCheckOwnerTest.createZa('14514', uHrs, UserHelper.SO_401, ZipCheckOwnerTest.hrsSeg1.Name, ZipCheckOwnerTest.hrsSeg1.Id, null, null, zas);

      Zip_Assignment__c za5 = ZipCheckOwnerTest.createZa('14514', uPeo, UserHelper.SO_PEO_ASO, ZipCheckOwnerTest.pasSeg1.Name, ZipCheckOwnerTest.pasSeg1.Id, null, null, zas);

      Zip_Assignment__c za6 = ZipCheckOwnerTest.createZa('14514', uHnb, UserHelper.SO_HNB, ZipCheckOwnerTest.hnbSeg1.Name, ZipCheckOwnerTest.hnbSeg1.Id, null, null, zas);

      Zip_Assignment__c za7 = ZipCheckOwnerTest.createZa('14516', unassignedCore, UserHelper.SO_CORE, ZipCheckOwnerTest.coreSeg1.Name, ZipCheckOwnerTest.coreSeg1.Id, null, null, zas);

      Zip_Assignment__c za8 = ZipCheckOwnerTest.createZa('14516', unassignedMMS, UserHelper.SO_MMS, ZipCheckOwnerTest.mmsSeg1.Name, ZipCheckOwnerTest.mmsSeg1.Id, null, null, zas);

      Zip_Assignment__c za9 = ZipCheckOwnerTest.createZa('14516', null, UserHelper.SO_401, ZipCheckOwnerTest.hrsSeg1.Name, ZipCheckOwnerTest.hrsSeg1.Id, null, null, zas);

      insert zas;
      // test results
      // make sure change records are created - should be one for each Zip Assignment record
      // MMS and PAY have fallback segments for tier 2 so those records will be created also.
      // if there's a team role an extra change record should be created
     // System.assertEquals(23,[Select count() from Zip_Assignment_Change__c]);
      TriggerMethods.clearVariables();
      // change the user on the core record
      za1.User__c = uCore2.Id;
      update za1;

      // should still only be three change records for this zip
      System.assertEquals(3,[Select count() from Zip_Assignment_Change__c where Zip_Assignment__c=:za1.Id]);
      
   } // testNewRecord

   // test the ZipCodeInformation trigger. 
   static testMethod void testZipCodeInformation() {
      Zip_Code_Information__c zci1 = new Zip_Code_Information__c(Name='1',Zip_Code_Key__c='1',County__c='TEST county');
      Zip_Code_Information__c zci2 = new Zip_Code_Information__c(Name='12345',Zip_Code_Key__c='12345',County__c='test COUNTY');
      Zip_Code_Information__c zci3 = new Zip_Code_Information__c(Name='7654321',Zip_Code_Key__c='76543',County__c='Test County');
      Zip_Code_Information__c zci4 = new Zip_Code_Information__c(Name='3',Zip_Code_Key__c='3',County__c='test county');
      Zip_Code_Information__c[] zcis = new Zip_Code_Information__c[]{zci1,zci2,zci3,zci4};
      insert zcis;
      
      checkZci(zci1.Id, '00001', 'Test County');
      checkZci(zci2.Id, '12345', 'Test County');
      checkZci(zci3.Id, '76543', 'Test County');
      checkZci(zci4.Id, '00003', 'Test County');
      
      // insert zip assignment records. Make sure they link up.
      Zip_Assignment__c za1 = new Zip_Assignment__c(Name='12345',Sales_Org__c=UserHelper.SO_CORE);
      Zip_Assignment__c za2 = new Zip_Assignment__c(Name='12345',Sales_Org__c=UserHelper.SO_MMS);
      Zip_Assignment__c za3 = new Zip_Assignment__c(Name='76543',Sales_Org__c=UserHelper.SO_CORE);
      Zip_Assignment__c za4 = new Zip_Assignment__c(Name='76543',Sales_Org__c=UserHelper.SO_MMS);
      // trigger will create a new record for this zip code
      Zip_Assignment__c za5 = new Zip_Assignment__c(Name='00002',Sales_Org__c=UserHelper.SO_CORE);
      Zip_Assignment__c za6 = new Zip_Assignment__c(Name='00002',Sales_Org__c=UserHelper.SO_MMS);
      Zip_Assignment__c[] zas = new Zip_Assignment__c[]{za1,za2,za3,za4,za5,za6};
      
      insert zas;

      checkZci(za1.Id, zci2.Id);      
      checkZci(za2.Id, zci2.Id);      
      checkZci(za3.Id, zci3.Id);      
      checkZci(za4.Id, zci3.Id);
      // get the id of the new Zip_Code_Information__c record
      za5 = [Select Id, Name, Zip_Code_Information__c from Zip_Assignment__c where Id = :za5.Id];
      Zip_Code_Information__c zci5 = [Select Id, Name, Zip_Code_Key__c from Zip_Code_Information__c where Id = :za5.Zip_Code_Information__c];
      System.assertEquals('00002',zci5.Name);
      System.assertEquals('Z00002',zci5.Zip_Code_Key__c);
      
      checkZci(za5.Id, zci5.Id);      
      checkZci(za6.Id, zci5.Id);
      
      // update 5 and 6 to zip 00001      
      za5.Name = '00001';
      za6.Name = '00001';
      
      zas = new Zip_Assignment__c[]{za5,za6};
      TriggerMethods.clearVariables();
      update zas;
      
      checkZci(za5.Id, zci1.Id);      
      checkZci(za6.Id, zci1.Id);
      
      // change the zip code to another valid one
      za5.Name = '00003';
      za6.Name = '00003';
      TriggerMethods.clearVariables();
      update zas;
      
      checkZci(za5.Id, zci4.Id);      
      checkZci(za6.Id, zci4.Id);
      
      // update to a bad one
      za5.Name = '00002';
      za6.Name = '00002';
      TriggerMethods.clearVariables();
      update zas;
      
      checkZci(za5.Id, zci5.Id);      
      checkZci(za6.Id, zci5.Id);
      
      
   } // testZipCodeInformation

   private static void checkZci(Id zciId, String zipCode, String countyName) {
      Zip_Code_Information__c zci = [Select Id, Name, Zip_Code_Key__c, County__c from Zip_Code_Information__c where Id=:zciId];
      System.assertEquals(zipCode,zci.Name);
      System.assertEquals(true,countyName.equalsIgnoreCase(zci.County__c));
   } // checkZci
   
   private static void checkZci(Id zaId, Id zciId) {
      Zip_Assignment__c za = [Select Id, Name, Zip_Code_Information__c from Zip_Assignment__c where Id = :zaId];
      System.assertEquals(zciId, za.Zip_Code_Information__c);
   } // checkZci

   
   public static Map<Id,Zip_Assignment__c> getAllZaMap() {
      Map<Id,Zip_Assignment__c> zipMap = new Map<Id,Zip_Assignment__c>([Select Id, Name, CriteriaToSkip__c, SkipJoinCriteria__c
                                                                              ,Sales_Org__c, Segment_Name__c, Zip_Segment__c 
                                                                          from Zip_Assignment__c]);
      return zipMap;
   } // getAllZaMap

   static testMethod void testSetTerritoryRep() {
      Org_Unit__c district = new Org_Unit__c(Name='10',Org_Type__c=OrgUnitMethods.TYPE_DISTRICT, Sales_Org__c=UserHelper.SO_CORE);
      insert district;
      ZipTerritory__c territory = new ZipTerritory__c(Name='Territory 1',District__c=district.Id);
      insert territory;
      territory = [Select Id, Name, Sales_Org__c, TerritoryRep__c, Rep_Name__c from ZipTerritory__c where Id=:territory.Id];
      
      ZipAssignment.setTerritoryRep(territory,null);
      User checkUser = new UserHelper().getUserById(territory.TerritoryRep__c);
      System.assertEquals(UserHelper.UNASSIGNED_CORE_PERSON_ID,checkUser.HR_Person_Id__c);
   } // testSetTerritoryRep


   static testMethod void testSegmentFallbacks() {
    UserHelperTest.setupSalesOrgSetting();
    
    // so the trigger fires.
      User runningUser = UserHelper.getRunningUser();

      // test creating new Zip_Assignment__c records
      // select test users
      User[] reps = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 5];
      User uCore = reps[0];
      User uCore2 = reps[1];
      User uMms = reps[2];
      User uMms2 = reps[3];
      User uHrs = reps[4];
       
      //User uCore = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE limit 1];
      //User uCore2 = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Id != :uCore.Id limit 1];
      //User uCore3 = [Select Id, FirstName, LastName, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Id != :uCore.Id and Id != :uCore2.Id limit 1];
      //User uMms = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_MMS limit 1];
      //User uHrs = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_401 limit 1];
      //User uPeo = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_PEO_ASO limit 1];
      //User uHnb = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_HNB limit 1];
      
      // make sure there are no change records
      System.assertEquals(0,[Select count() from Zip_Assignment_Change__c]);
      ZipCheckOwnerTest.setupSegments();
      
      // verify the unassigned users exist
      User unassignedCore = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where IsActive=true and HR_Person_Id__c=:UserHelper.UNASSIGNED_CORE_PERSON_ID limit 1];
      User unassignedMMS = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where IsActive=true and HR_Person_Id__c=:UserHelper.UNASSIGNED_MMS_PERSON_ID limit 1];
      
      // create Zip Assignment records
      Zip_Assignment__c[] zas = new Zip_Assignment__c[]{};
      
      Zip_Assignment__c za1 = ZipCheckOwnerTest.createZa('14514', uCore, UserHelper.SO_CORE, ZipCheckOwnerTest.coreSeg1.Name, ZipCheckOwnerTest.coreSeg1.Id, null, null, zas);
      Zip_Assignment__c za2 = ZipCheckOwnerTest.createZa('14514', uMms, UserHelper.SO_MMS, ZipCheckOwnerTest.mmsSeg1.Name, ZipCheckOwnerTest.mmsSeg1.Id, null, null, zas);
      Zip_Assignment__c za3 = ZipCheckOwnerTest.createZa('14514', uHrs, UserHelper.SO_401, ZipCheckOwnerTest.hrsSeg1.Name, ZipCheckOwnerTest.hrsSeg1.Id, null, null, zas);
      insert zas;
       
      // test results
      // make sure change records are created - should be one for each Zip Assignment record
      // if there's a team role an extra change record should be created
      //System.assertEquals(8,[Select count() from Zip_Assignment_Change__c]);
      //System.assertEquals(6,[Select count() from ZipAssignmentFallback__c]);

      zas.clear();
      // don't include the segment id to force the code to find the segments
      Zip_Assignment__c za1a = ZipCheckOwnerTest.createZa('14514', uCore2, UserHelper.SO_CORE, ZipCheckOwnerTest.coreSeg2.Name, null , null, null, zas);
      Zip_Assignment__c za2a = ZipCheckOwnerTest.createZa('14514', uMms2, UserHelper.SO_MMS, ZipCheckOwnerTest.mmsSeg2.Name, null , null, null, zas);
      TriggerMethods.clearVariables();
      insert zas;
       
     // System.assertEquals(9,[Select count() from Zip_Assignment_Change__c]);
     // System.assertEquals(4,[Select count() from ZipAssignmentFallback__c]);

      // delete two zip assignments to force them to reevaluate
      zas = new Zip_Assignment__c[]{za1a, za2a};
      TriggerMethods.clearVariables();
      delete zas;
       
      //System.assertEquals(9,[Select count() from Zip_Assignment_Change__c]);
      //System.assertEquals(6,[Select count() from ZipAssignmentFallback__c]);

      // just for code coverage
      ZipAssignment.SKIP_TRIGGER=true;
      zas.clear();
      Zip_Assignment__c za1b = ZipCheckOwnerTest.createZa('14515', uCore2, UserHelper.SO_CORE, ZipCheckOwnerTest.coreSeg2.Name, ZipCheckOwnerTest.coreSeg2.Id, null, null, zas);
      Zip_Assignment__c za2b = ZipCheckOwnerTest.createZa('14515', uMms2, UserHelper.SO_MMS, ZipCheckOwnerTest.mmsSeg2.Name, ZipCheckOwnerTest.mmsSeg2.Id, null, null, zas);
      TriggerMethods.clearVariables();
      insert zas;

      // nothing should change
      //System.assertEquals(9,[Select count() from Zip_Assignment_Change__c]);
     // System.assertEquals(6,[Select count() from ZipAssignmentFallback__c]);
       

   } // testSegmentFallbacks

} // class ZipAssignmentTest