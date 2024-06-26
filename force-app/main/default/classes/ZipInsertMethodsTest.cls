/* Test Methods on the ZipInsertMethods class
   
  History
  -------
  03/14/2015 Dan Carmen   Created
  09/05/2023 Dan Carmen   Add handleTrigger method to be able to launch a batch from the trigger.
  02/09/2024 Dan Carmen   Extra check for creating a change record
  
 */
@isTest
private class ZipInsertMethodsTest {
    @testSetup
    public static void testSetup() {
       Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name=ZipInsertBatch.CLASSNAME, Active__c=true, BatchSize__c=100);
       insert abc;
    } // testSetup
    
	static Zip_Segment__c segment1;
   static Org_Unit__c dist1;
   static Org_Unit__c dist2;
   static ZipTerritory__c terr1;
   static ZipTerritory__c terr2;
   static Zip_Assignment__c za1;
   static Zip_Assignment__c za2;
   static Zip_Assignment__c za3;
   static Zip_Assignment__c za4;

   
   static void setup() {
   	segment1 = new Zip_Segment__c(Name='Default', Sales_Org__c=UserHelper.SO_CORE);
   	insert segment1;
   	
      // create districts
      dist1 = new Org_Unit__c(Name='1',Org_Unit_Name__c='District 1', Sales_Org__c=UserHelper.SO_CORE
                                         ,Org_Type__c=OrgUnitMethods.TYPE_DISTRICT);
      dist2 = new Org_Unit__c(Name='2',Org_Unit_Name__c='District 2', Sales_Org__c=UserHelper.SO_CORE
                                         ,Org_Type__c=OrgUnitMethods.TYPE_DISTRICT);
      Org_Unit__c[] districts = new Org_Unit__c[]{dist1,dist2};
      insert districts;
      
      // select territory reps
      User[] reps = [Select Id, Name, HR_Person_Id__c from User where Sales_Org__c=:UserHelper.SO_CORE and IsActive=true limit 2];
      
      // create territories
      terr1 = new ZipTerritory__c(District__c=dist1.Id, Name='Territory 1',Territory_Nbr__c='1',TerritoryRep__c=reps[0].Id
                                 ,Zip_Segment__c=segment1.Id);
      terr2 = new ZipTerritory__c(District__c=dist2.Id, Name='Territory 2',Territory_Nbr__c='2',TerritoryRep__c=reps[1].Id
                                 ,Zip_Segment__c=segment1.Id);
      ZipTerritory__c[] territories = new ZipTerritory__c[]{terr1,terr2};
      insert territories;
      
      // create a few zip codes
      za1 = new Zip_Assignment__c(Name='12345',District__c=dist1.Id, HR_Person_Id__c=reps[0].HR_Person_Id__c, Rep_Name__c=reps[0].Name
                                 ,Sales_Org__c=UserHelper.SO_CORE, Segment_Name__c=segment1.Name
                                 ,ZipTerritory__c=terr1.Id, User__c=reps[0].Id, Zip_Segment__c=segment1.Id);
      za2 = new Zip_Assignment__c(Name='12346',District__c=dist1.Id, HR_Person_Id__c=reps[0].HR_Person_Id__c, Rep_Name__c=reps[0].Name
                                 ,Sales_Org__c=UserHelper.SO_CORE, Segment_Name__c=segment1.Name
                                 ,ZipTerritory__c=terr1.Id, User__c=reps[0].Id, Zip_Segment__c=segment1.Id);
      za3 = new Zip_Assignment__c(Name='12347',District__c=dist2.Id, HR_Person_Id__c=reps[1].HR_Person_Id__c, Rep_Name__c=reps[1].Name
                                 ,Sales_Org__c=UserHelper.SO_CORE, Segment_Name__c=segment1.Name
                                 ,ZipTerritory__c=terr2.Id, User__c=reps[1].Id, Zip_Segment__c=segment1.Id);
      za4 = new Zip_Assignment__c(Name='12348',District__c=dist2.Id, HR_Person_Id__c=reps[1].HR_Person_Id__c, Rep_Name__c=reps[1].Name
                                 ,Sales_Org__c=UserHelper.SO_CORE, Segment_Name__c=segment1.Name
                                 ,ZipTerritory__c=terr2.Id, User__c=reps[1].Id, Zip_Segment__c=segment1.Id);
      Zip_Assignment__c[] zips = new Zip_Assignment__c[]{za1,za2,za3,za4};
      insert zips;                                 
   } // setup
   
   @isTest
   static void testDistrictMatch() {
   	setup();
   	// verify zips are in districts
   	System.assertEquals(2,[select count() from Zip_Assignment__c where District__c=:dist1.Id and ZipTerritory__c=:terr1.Id]);
      System.assertEquals(2,[select count() from Zip_Assignment__c where District__c=:dist2.Id and ZipTerritory__c=:terr2.Id]);
   	
      // create a file to load
      String fileText = ManageZipAssignController.HEADER_DISTRICT+','+ManageZipAssignController.HEADER_SALES_ORG+','+ManageZipAssignController.HEADER_ZIP_CODE+','+ManageZipAssignController.HEADER_ZIP_SEGMENT+','+ManageZipAssignController.HEADER_ZIP_TERRITORY+'\n';
      // move a zip from district 1 to district 2
      fileText += dist2.Name+','+dist2.Sales_Org__c+','+za1.Name+','+segment1.Name+','+terr2.Name+'\n';
      // create a new zip in district 1
      fileText += dist1.Name+','+dist1.Sales_Org__c+',21212,'+segment1.Name+','+terr1.Name+'\n';
      // use a bad district/territory combination
      fileText += dist1.Name+','+dist1.Sales_Org__c+',21213,'+segment1.Name+','+terr2.Name+'\n';
      // use a bad district
      fileText += '66'+','+dist1.Sales_Org__c+',21212,'+segment1.Name+','+terr1.Name+'\n';
      
      Blob fileBlob = Blob.valueOf(fileText);
      String fileName='testfile.csv';
      
      ManageZipAssignController mzac = new ManageZipAssignController();
      mzac.csvFileBody = null;
      mzac.csvAsString = null;
      // don't set a file name - should get an error
      mzac.importCSVFile();
      System.assertEquals(false,mzac.importOkay);
      
      mzac.csvFileBody = fileBlob;
      mzac.csvAsString=fileName;
      mzac.importCSVFile();
      System.assertEquals(true,mzac.importOkay);
      
      System.assertEquals(1,[select count() from ZipImport__c]);
      System.assertEquals(4,[select count() from ZipImportDetail__c]);
      
      // run the batch process
      Test.startTest();
      ZipImport__c zipImp = [Select Id, RunBatch__c from ZipImport__c limit 1];
      zipImp.RunBatch__c = true;
      update zipImp;
      //ZipInsertBatch.launchBatch();
      Test.stopTest();
       
      zipImp = [Select Id, RunBatch__c from ZipImport__c limit 1];
      Assert.isFalse(zipImp.RunBatch__c);
      
      
   } // testDistrictMatch
   
   static testMethod void testScheduleBatch() {
      TestHelper.testScheduler(ZipInsertBatch.CLASSNAME+'Test', new ZipInsertBatch());
   }

} // class ZipInsertMethodsTest