/**
 * 02/04/2016  Lynn Michels           Created
   09/21/2017 Dan Carmen              Change to use Custom Metadata Type
   12/12/2017 Dan Carmen              Additional adjustments to asset code
   06/17/2021 Dan Carmen        Added CSCMContractStatus__c to account query

 */
@isTest
private class AssetMappingToProductIndicatorsTest {

   public static AssetPlanCode__mdt[] getTestData(String testName) {
      AssetPlanCode__mdt[] planCodes = [select Label
                                          ,TestScenario__c
                                          ,(select AssetPlanCode__r.Label
                                                ,AssetPlanCode__r.TestScenario__c
                                                ,AssetProductField__r.Label
                                                ,AssetProductField__r.PicklistValue__c
                                            From AssetPlanFldLinks__r
                                           Where IsActive__c=true)
                                    from AssetPlanCode__mdt
                                    where TestScenario__c = :testName];
      System.debug('getTestData links='+planCodes.size());

      // verify we get data back
      System.assertEquals(true, planCodes.size() > 0, 'Test Data for '+testName+' Not found!');
      return planCodes;
   } // getTestData
   
   public static void initAssetTest() {
      AssetMappingToProductIndicators.overrideIdSet.clear();
      AssetMappingToProductIndicators.accountIdSet.clear();
      AssetMappingToProductIndicators.acctMap.clear();
      AssetMappingToProductIndicators.fieldsToClearByAcctIdMap.clear();
      AssetMappingToProductIndicators.acctFldNameSet.clear(); 
      AssetMappingToProductIndicators.activeFldValueSet.clear();
      AssetMappingToProductIndicators.acctIdsProcessedSet.clear();
      
      //AssetMappingToProductIndicators.assetByAcctIdMap.clear();
      //AssetMappingToProductIndicators.planCodeSetByAcctId.clear();
      //AssetMappingToProductIndicators.acctList.clear();
      
   } // initAssetTest

   //test inserting one asset with no start date, set a start date, set a cancel date, delete
   static testMethod void testOneProductIndicator() {
      
      AssetPlanCode__mdt[] planCodes = getTestData('Test 1');
      
      String planCode = planCodes[0].Label;
      String fldName = planCodes[0].AssetPlanFldLinks__r[0].AssetProductField__r.Label;
      
      // create an Account record
      Account acct = new Account(Name='Test Acct');
      insert acct;
      
      //create new Asset with no start or end date
      Asset asst1 = new Asset(Name='Asset1', AccountId=acct.Id, Paychex_Asset_Id__c='1', Product_Plan_Code__c=planCode);
      insert asst1;
        
      String acctQuery = 'Select Id, '+fldName+' from Account where Id=\''+acct.Id+'\'';
      Account[] accts = Database.query(acctQuery);      
      System.assertEquals(false, (Boolean)accts[0].get(fldName));

      initAssetTest();

      //Give the Asset a Start date which will trigger the product indicator box to be checked
      asst1.Start_Date__c = Date.TODAY();
      update asst1;
        
      accts = Database.query(acctQuery); 
      System.assertEquals(true, (Boolean)accts[0].get(fldName));
        
      initAssetTest();

      //Give the Asset a Cancel date which will trigger the product indicator box to be UNchecked
      Date cancelDate = Date.TODAY();
      asst1.Plan_Cancel_Date__c = cancelDate.addDays(15);
      update asst1;
        
      accts = Database.query(acctQuery); 
      System.assertEquals(false, (Boolean)accts[0].get(fldName));
        
      initAssetTest();
      //set up the Asset so the box will be checked again
      asst1.Start_Date__c = Date.TODAY();
      asst1.Plan_Cancel_Date__c = null;
      update asst1;
        
      accts = Database.query(acctQuery); 
      System.assertEquals(true, (Boolean)accts[0].get(fldName));
        
      initAssetTest();
      //delete the asset and the box will be unchecked
      delete asst1;
        
      accts = Database.query(acctQuery); 
      System.assertEquals(false, (Boolean)accts[0].get(fldName));

   } // testOneProductIndicator

   //test with two checkbox assets.
   static testMethod void testProductIndicators() {
   
      AssetPlanCode__mdt[] planCodes1 = getTestData('Test 1');
      String planCode1 = planCodes1[0].Label;
      String fldName1 = planCodes1[0].AssetPlanFldLinks__r[0].AssetProductField__r.Label;

      AssetPlanCode__mdt[] planCodes2 = getTestData('Test 2');
      String planCode2 = planCodes2[0].Label;
      String fldName2 = planCodes2[0].AssetPlanFldLinks__r[0].AssetProductField__r.Label;

      // create an Account record
      Account acct = new Account(Name='Test Acct');
      insert acct;
      
      //create new Asset with no start or end date
      Asset asst1 = new Asset(Name='Asset1', AccountId=acct.Id, Paychex_Asset_Id__c='1', Product_Plan_Code__c=planCode1, Start_Date__c = Date.TODAY());
      Asset asst2 = new Asset(Name='Asset2',AccountId=acct.Id, Paychex_Asset_Id__c='2',Product_Plan_Code__c=planCode2);
      Asset[] assets = new Asset[]{asst1,asst2};
      insert assets;

      String acctQuery = 'Select Id, '+fldName1+','+fldName2+' from Account where Id=\''+acct.Id+'\'';
      Account[] accts = Database.query(acctQuery);      
      System.assertEquals(true, (Boolean)accts[0].get(fldName1));
      System.assertEquals(false, (Boolean)accts[0].get(fldName2));

      initAssetTest();
      //Give the Asset2 a Start date which will trigger the product indicator box to be checked
      asst2.Start_Date__c = Date.TODAY();
      update asst2;
        
      accts = Database.query(acctQuery);      
      System.assertEquals(true, (Boolean)accts[0].get(fldName1));
      System.assertEquals(true, (Boolean)accts[0].get(fldName2));
        
      initAssetTest();
      //Give the Asset1 a Cancel date which will trigger the product indicator box to be UNchecked
      Date cancelDate = Date.TODAY();
      asst1.Plan_Cancel_Date__c = cancelDate.addDays(15);
      update asst1;
        
      accts = Database.query(acctQuery);      
      System.assertEquals(false, (Boolean)accts[0].get(fldName1));
      System.assertEquals(true, (Boolean)accts[0].get(fldName2));
        
      initAssetTest();
      //delete the asset2 and the box will be unchecked
      delete asst2;
        
      accts = Database.query(acctQuery);      
      System.assertEquals(false, (Boolean)accts[0].get(fldName1));
      System.assertEquals(false, (Boolean)accts[0].get(fldName2));
   } // testProductIndicators

   //test with picklist assets.
   static testMethod void testProductPicklists() {

      AssetPlanCode__mdt[] planCodes1 = getTestData('Test 1');
      system.debug('LM test 1 '+planCodes1);    
      String planCode1 = planCodes1[0].Label;  //1001
      String fldName1 = planCodes1[0].AssetPlanFldLinks__r[0].AssetProductField__r.Label;  //Expense_Manager__c

      // picklist field
      AssetPlanCode__mdt[] planCodes3 = getTestData('Test 3');  
      String planCode3 = planCodes3[0].Label;  
      String fldName3 = planCodes3[0].AssetPlanFldLinks__r[0].AssetProductField__r.Label;  //Time_and_Attendance
      String picklistValue3 = planCodes3[0].AssetPlanFldLinks__r[0].AssetProductField__r.PicklistValue__c; //TLO
      // same picklist field, different picklist value
      AssetPlanCode__mdt[] planCodes4 = getTestData('Test 4');   
      String planCode4 = planCodes4[0].Label; //1263
      String fldName4 = planCodes4[0].AssetPlanFldLinks__r[0].AssetProductField__r.Label; //Time_and_Attendance
      String picklistValue4 = planCodes4[0].AssetPlanFldLinks__r[0].AssetProductField__r.PicklistValue__c; //Stratus Time
      // make sure we're hitting the test conditions
      System.assertEquals(fldName3,fldName4,'Picklist field names are not the same!');
      System.assertEquals(false, picklistValue3 == picklistValue4, 'Picklists values are the same!');
      
      // create an Account record
      Account acct = new Account(Name='Test Acct');
      insert acct;
      
      //insert two assets
      Asset asst1 = new Asset(Name='Asset1', AccountId=acct.Id, Paychex_Asset_Id__c='1', Product_Plan_Code__c=planCode1, Start_Date__c = Date.TODAY());
      Asset asst3 = new Asset(Name='Asset3', AccountId=acct.Id, Paychex_Asset_Id__c='2', Product_Plan_Code__c=planCode3, Start_Date__c = Date.TODAY());
      Asset[] assets = new Asset[]{asst1,asst3};
      insert assets;
        
      String acctQuery = 'Select Id, '+fldName1+','+fldName3+' from Account where Id=\''+acct.Id+'\'';
      Account[] accts = Database.query(acctQuery);      
      System.assertEquals(true, (Boolean)accts[0].get(fldName1));
      System.assertEquals(picklistValue3, (String)accts[0].get(fldName3));
        
        
      initAssetTest();
      //give asset2 a cancel date
      Date cancelDate = Date.TODAY();
      asst3.Plan_Cancel_Date__c = cancelDate.addDays(15);
      asst3.Trigger_Update__c = true;
      update asst3;
        
      //the field that corresponds with asset2 on the account, should be removed
      accts = Database.query(acctQuery);      
      System.assertEquals(true, (Boolean)accts[0].get(fldName1));
      System.assertEquals(null, (String)accts[0].get(fldName3));
              
      initAssetTest();
      //insert another asset
      Asset asst4 = new Asset(Name='Asset4', AccountId=acct.Id, Paychex_Asset_Id__c='3', Product_Plan_Code__c=planCode4, Start_Date__c = Date.TODAY());
      insert asst4;
        
      accts = Database.query(acctQuery);      
      System.assertEquals(true, (Boolean)accts[0].get(fldName1));
      System.assertEquals(picklistValue4, (String)accts[0].get(fldName4));
        
      initAssetTest();

      delete asst4;
        
      accts = Database.query(acctQuery);      
      System.assertEquals(true, (Boolean)accts[0].get(fldName1));
      System.assertEquals(null, (String)accts[0].get(fldName4));
   } // testProductPicklists

   //test with 2 plan codes that map to the same checkbox
   static testMethod void test2PlanCodes1Checkbox() {
      AssetPlanCode__mdt[] planCodes1 = getTestData('Test 5');
      String planCode1 = planCodes1[0].Label;
      String fldName1 = planCodes1[0].AssetPlanFldLinks__r[0].AssetProductField__r.Label;
      
      // gather all of the field names (in case there's more than one) so we can make sure we're using the right
      // field name in the test
      Set<String> fldNameSet = new Set<String>();
      for (AssetPlanFldLink__mdt apfl : planCodes1[0].AssetPlanFldLinks__r) {
         fldNameSet.add(apfl.AssetProductField__r.Label);
      }

      AssetPlanCode__mdt[] planCodes2 = getTestData('Test 6');
      String planCode2 = planCodes2[0].Label;
      System.assertEquals(true, planCode1 != planCode2, 'Plan codes for Test 5 and Test 6 are both '+planCode1+' and they should be different!');
      
      String fldNameCheckbox = null;
      for (AssetPlanFldLink__mdt apfl : planCodes2[0].AssetPlanFldLinks__r) {
         if (fldNameSet.contains(apfl.AssetProductField__r.Label)) {
            fldNameCheckbox = apfl.AssetProductField__r.Label;
            break;
         }
      } // for
      // make sure we have a common field to use
      System.assertEquals(true, String.isNotBlank(fldNameCheckbox), 'A common field for '+planCode1+' and '+planCode2+' cound not be found!');
      
      // create an Account record
      Account acct = new Account(Name='Test Acct');
      insert acct;
      
      //insert two assets
      Asset asst1 = new Asset(Name=planCode1, AccountId=acct.Id, Paychex_Asset_Id__c='1', Product_Plan_Code__c=planCode1, Start_Date__c = Date.TODAY());
      Asset asst2 = new Asset(Name=planCode2, AccountId=acct.Id, Paychex_Asset_Id__c='2', Product_Plan_Code__c=planCode2, Start_Date__c = Date.TODAY());
      Asset[] assets = new Asset[]{asst1,asst2};
      insert assets;

      String acctQuery = 'Select Id, '+fldNameCheckbox+' from Account where Id=\''+acct.Id+'\'';
      Account[] accts = Database.query(acctQuery);      
      System.assertEquals(true, (Boolean)accts[0].get(fldNameCheckbox));
        
      initAssetTest();
      //give asset2 a cancel date
      Date cancelDate = Date.TODAY();
      asst2.Plan_Cancel_Date__c = cancelDate.addDays(15);
      //asst2.Trigger_Update__c = true;
      update asst2;

      // should still be true since they look at the same field
      accts = Database.query(acctQuery);      
      System.assertEquals(true, (Boolean)accts[0].get(fldNameCheckbox));
      
      initAssetTest();
      //give asset1 a cancel date
      asst1.Plan_Cancel_Date__c = cancelDate.addDays(15);
      //asst1.Trigger_Update__c = true;
      update asst1;

      // should now be false since they're both ended
      accts = Database.query(acctQuery);      
      System.assertEquals(false, (Boolean)accts[0].get(fldNameCheckbox));
      
      initAssetTest();
      //remove the cancel date from asset2
      asst2.Plan_Cancel_Date__c = null;
      //asst2.Trigger_Update__c = true;
      update asst2;

      // should still be true since they look at the same field
      accts = Database.query(acctQuery);      
      System.assertEquals(true, (Boolean)accts[0].get(fldNameCheckbox));
      
      
   } // test2PlanCodes1Checkbox

} // class AssetMappingToProductIndicatorsTest