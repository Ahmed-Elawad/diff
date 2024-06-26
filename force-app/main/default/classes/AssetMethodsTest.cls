/* 
 * Test methods for the AssetMethods class.
 *
 * History
 * -------
   07/23/2012 Dan Carmen      Created - Merged in code from UpdateTaskEventTest
   02/11/2013 Carrie Marciano	added code for testupdateTAARefObjRecord
   08/30/2106 Lynn Michels	   commented out SeeAllData=true, added criteria to check update to Accounts for lost reason and lost date
   12/08/2017 Dan Carmen      Consolidate code

 */
//@isTest(SeeAllData=true)
@isTest
private class AssetMethodsTest {

   static testMethod void testMatchProduct() {
      AssetMethods.PERFORM_PROD_CHECK = true;
   	// setup the products
      String[] prodNames = new String[]{'AssetMethodsTest1','AssetMethodsTest2','AssetMethodsTest3'};
      PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames,'AMTSalesOrg',null);

      // map products
      Product_Mapping__c pm1 = new Product_Mapping__c(Type__c=AssetMethods.PM_TYPE, Sales_Org__c='AMTSalesOrg', Product_Code__c='AssetMethodsTest1', Plan_Code__c='Test1');
      Product_Mapping__c pm2 = new Product_Mapping__c(Type__c=AssetMethods.PM_TYPE, Sales_Org__c='AMTSalesOrg', Product_Code__c='AssetMethodsTest2', Admin_By__c='T2', Ext_App_Id__c='T2', Plan_Type__c='T2');
      Product_Mapping__c pm3 = new Product_Mapping__c(Type__c=AssetMethods.PM_TYPE, Sales_Org__c='AMTSalesOrg', Product_Code__c='AssetMethodsTest3', Admin_By__c='T3', Ext_App_Id__c='T3', Plan_Type__c='T3');
      Product_Mapping__c[] mappings = new Product_Mapping__c[]{pm1,pm2,pm3};
      insert mappings;
      
      // create an account record.
      Account acct = new Account(Name='Test Acct');
      insert acct;
      
      Asset asst1 = new Asset(Name='Asset1',AccountId=acct.Id,Product_Plan_Code__c='Test1', Bundle_Code__c='Test');
      Asset asst2 = new Asset(Name='Asset2',AccountId=acct.Id,Product_Plan_Code__c='Test2');
      Asset asst3 = new Asset(Name='Asset3',AccountId=acct.Id,Admin_By__c='T2',Ext_App_Id__c='T2',Plan_Type__c='T2');
      Asset asst4 = new Asset(Name='Asset4',AccountId=acct.Id,Admin_By__c='T2',Ext_App_Id__c='T1',Plan_Type__c='T2');
      Asset asst5 = new Asset(Name='Asset5',AccountId=acct.Id,Admin_By__c='T4',Ext_App_Id__c='T3',Plan_Type__c='T3');
      Asset asst6 = new Asset(Name='Asset6',AccountId=acct.Id,Admin_By__c='T3',Ext_App_Id__c='T3',Plan_Type__c='T3');
      
      Asset[] assts = new Asset[]{asst1,asst2,asst3,asst4,asst5,asst6};
      insert assts;
      
      // check results
      testAsset('asst1',asst1.Id,'AssetMethodsTest1');
      testAsset('asst2',asst2.Id,null);
      testAsset('asst3',asst3.Id,'AssetMethodsTest2');
      testAsset('asst4',asst4.Id,null);
      testAsset('asst5',asst5.Id,null);
      testAsset('asst6',asst6.Id,'AssetMethodsTest3');
      
      // update assets so all match.
      asst2.Product_Plan_Code__c='Test1';
      asst4.Ext_App_Id__c='T2';
      asst5.Admin_By__c='T3';
      asst6.Plan_Type__c='T4';
      update assts;
      
      // check results
      asst1 = testAsset('asst1',asst1.Id,'AssetMethodsTest1');
      asst2 = testAsset('asst2',asst2.Id,'AssetMethodsTest1');
      asst3 = testAsset('asst3',asst3.Id,'AssetMethodsTest2');
      asst4 = testAsset('asst4',asst4.Id,'AssetMethodsTest2');
      asst5 = testAsset('asst5',asst5.Id,'AssetMethodsTest3');
      asst6 = testAsset('asst6',asst6.Id,null);
   } // testMatchProduct
   
   private static Asset testAsset(String testName, Id assetId, String productName) {
   	System.debug('Testing '+testName);
   	Asset asst = [Select Id, Name, AccountId, Product_Plan_Code__c, Admin_By__c,Ext_App_Id__c,Plan_Type__c
   	                    ,Product2Id,Product2.Name
   	                from Asset
   	               Where Id = :assetId];
   	if (productName == null) {
   	   System.assertEquals(null,asst.Product2Id);
   	} else {
         System.assertEquals(productName, asst.Product2.Name);
   	}
   	return asst;
   } // testAsset
   
   static testMethod void testUpdateTaskEvent() {
      ZipCheckOwner.SKIP_TRIGGERS=true;
      TaskHelper.SKIP_TRIGGERS = true;
      Account a1 = new Account(Name='Test');
      insert a1;

      // get the record type info
      Map<String,Schema.RecordTypeInfo> byName = new Map<String,Schema.RecordTypeInfo>();
      String[] recordTypeNames = new String[]{};
      recordTypeNames.addAll(AssetMethods.actyRecordTypeNames);
      // add in a couple of non-premier record types to make sure they're not affected
      recordTypeNames.add(RecordTypeHelper.CORE_EVENT);
      recordTypeNames.add(RecordTypeHelper.CORE_TASK);
       
       String[] objectNames = new String[]{'Task','Event'};
       RecordTypeHelper.getRecordTypesMap(objectNames, recordTypeNames, null, byName);
       
       Id eventPremRtId = byName.get('2008-09 Premier Safety Event Record Type').getRecordTypeId();
       Id taskPremRtId = byName.get('2008-09 Premier Safety Task Record Type').getRecordTypeId();
       Id eventCoreRtId = byName.get(RecordTypeHelper.CORE_EVENT).getRecordTypeId();
       Id taskCoreRtId = byName.get(RecordTypeHelper.CORE_TASK).getRecordTypeId();
       
       DateTime testDateTime = System.now().addDays(7);

       // create some activity
       Event evnt1 = new Event(WhatId=a1.id,
                             RecordTypeId=eventPremRtId,
                             StartDateTime=testDateTime,
                             EndDateTime=testDateTime+1,                            
                             ActivityDate=testDateTime.date(),
                             HR_Solution_Cancel__c=null);
       Event evnt2 = new Event(WhatId=a1.id,
                             RecordTypeId=eventCoreRtId,
                             StartDateTime=testDateTime,
                             EndDateTime=testDateTime+1,                            
                             ActivityDate=testDateTime.date(),
                             HR_Solution_Cancel__c=null);
       Event[] evnts = new Event[]{evnt1,evnt2};
       insert evnts;
       
       Task tsk1 = new Task(WhatId=a1.Id,
                           RecordTypeId=taskPremRtId,
                           ActivityDate=testDateTime.date(),
                           Status='Not Started',
                           Priority='Low',
                           HR_Solution_Cancel__c=null);                         
       Task tsk2 = new Task(WhatId=a1.Id,
                           RecordTypeId=taskCoreRtId,
                           ActivityDate=testDateTime.date(),
                           Status='Not Started',
                           Priority='Low',
                           HR_Solution_Cancel__c=null);
       Task[] tsks = new Task[]{tsk1,tsk2};                         
       insert tsks;

       // create multiple assets
       Asset[] premierAssets = new Asset[]{};
       // create an asset for each premier plan code
       for (String planCode : AssetMethods.planCodesSet) {
          Asset asst = new Asset(Name='Asset '+planCode,Product_plan_Code__c=planCode,Start_Date__c=Date.today(), Plan_Cancel_Date__c=null,AccountId=a1.Id);
          premierAssets.add(asst);
       }
       Asset asstNonPremier = new Asset(Name='Non-Premier',Product_plan_Code__c='1',Start_Date__c=Date.today(),Plan_Cancel_Date__c=null,AccountId=a1.Id);
       Asset[] allAssets = new Asset[]{};
       allAssets.addAll(premierAssets);
       allAssets.add(asstNonPremier);

       // save the records
       insert allAssets;

       // activity should not have changed - no cancel dates on any of the assets
       checkEvents(evnt1.Id,null,evnt2.Id,null);
       checkTasks(tsk1.Id,null,tsk2.Id,null);
       
       // update the cancel date on only one of the premier assets
       Asset asst1 = premierAssets.get(0);
       asst1.Plan_Cancel_Date__c = Date.today();
       update asst1;

       // activity should not have changed - only one has a cancel date - all others do not.
       checkEvents(evnt1.Id,null,evnt2.Id,null);
       checkTasks(tsk1.Id,null,tsk2.Id,null);
       
       // update cancel date on all assets
       for (Asset asst : allAssets) {
          asst.Plan_Cancel_Date__c = Date.today();
       }
       update allAssets;

       // premier activity should have updated
       checkEvents(evnt1.Id,'Yes',evnt2.Id,null);
       checkTasks(tsk1.Id,'Yes',tsk2.Id,null);

       // remove the cancel date from the non-premier asset. Nothing should change
       asstNonPremier.Plan_Cancel_Date__c = null;
       update asstNonPremier;

       // Should be the same
       checkEvents(evnt1.Id,'Yes',evnt2.Id,null);
       checkTasks(tsk1.Id,'Yes',tsk2.Id,null);

       // remove the cancel date on one of the premier assets
       asst1.Plan_Cancel_Date__c = null;
       update asst1;

       // premier activity should now be null
       checkEvents(evnt1.Id,'No',evnt2.Id,null);
       checkTasks(tsk1.Id,'No',tsk2.Id,null);

   } // testUpdateTaskEvent

   static testMethod void testupdateTAARefObjRecord() {
      ZipCheckOwner.SKIP_TRIGGERS=true;
      Account a1 = new Account(Name='TAATest');
      insert a1;
      Contact c1_a1 = new Contact(FirstName='Test Account1',LastName='Contact 1', AccountId=a1.Id, Email='c1a1@gmail.com');
      insert c1_a1;
       
      Asset asst992 = new Asset(Name='TIME & LABOR SW',Product_plan_Code__c='992',Start_Date__c=Date.today(),Plan_Cancel_Date__c=null,AccountId=a1.Id);
      Asset asst993 = new Asset(Name='T&L SW INVOICE',Product_plan_Code__c='993',Start_Date__c=Date.today(),Plan_Cancel_Date__c=null,AccountId=a1.Id);
      Asset asst1053 = new Asset(Name='TLO Bundle PKG',Product_plan_Code__c='1053',Start_Date__c=Date.today(),Plan_Cancel_Date__c=null,AccountId=a1.Id);
      Asset[] TAAAssets = new Asset[]{asst992,asst993,asst1053};
      // save the records
      insert TAAAssets;
       
      // create Onboarding Case, Onboarding RefObj
      Case OBCase = new Case(AccountId=a1.id,
                              RecordTypeId='01270000000HgOc',
                              Contact=c1_a1,
                              Reassign_Category_1__c='AS East');
      // save the records
      insert OBCase;
       
      //set Onboarding RefObj to Graduated - client now "in support"
      Reference_TAA__c OBRefObj = [Select Id, Client_Graduated__c, Current_Step__c from Reference_TAA__c where Case_Lookup__c=:OBCase.Id];
      OBRefObj.Client_Graduated__c=True;
      update OBRefObj;
       
      // update the cancel date on only one of the premier assets
      Asset updateAsset = [select Id, Plan_Cancel_Date__c from Asset where AccountId=:a1.id and Product_Plan_Code__c='992'];
      updateAsset.Plan_Cancel_Date__c=date.today();
      update updateAsset;

      // Support RefObj should not have changed - remain at Client Graduated
      Reference_TAA__c SupRefObj = [Select Id, Client_Graduated__c, Current_Step__c from Reference_TAA__c where Case_Lookup__r.Account.Id=:a1.id and RecordTypeId='01270000000UJwJ'];
      System.assertEquals('Client Graduated',SupRefObj.Current_Step__c);
       
      // update cancel date on all assets
      Asset[] endTAAAssets = [Select Id, Name,Product_Plan_Code__c, Plan_Cancel_Date__c 
      						from Asset
      						where AccountId=:a1.Id];
      
      Asset[] updateTAAAssets = new Asset[]{};  
      
      for (Asset endTAAAsset : endTAAAssets){
         if (endTAAAsset.Product_Plan_Code__c == '992' || endTAAAsset.Product_Plan_Code__c == '993' || endTAAAsset.Product_Plan_Code__c == '1053' ) {
            endTAAAsset.Plan_Cancel_Date__c = date.today();
            updateTAAAssets.add(endTAAAsset); 
         }           
      } // for   
                 
      if (!updateTAAAssets.isEmpty()) {
        update updateTAAAssets;
      }          

      // Support RefObj should have changed - Cancelled in Support
      Reference_TAA__c endSupRefObj = [Select Id, Client_Graduated__c, Current_Step__c from Reference_TAA__c where Case_Lookup__r.Account.Id=:a1.id and RecordTypeId='01270000000UJwJ'];
      System.assertEquals('Cancelled In Support',endSupRefObj.Current_Step__c);
   } // testupdateTAARefObjRecord

   static testMethod void testpopulateClientStartDate() {
       Account a1 = new Account(Name='Test Account');
       insert a1;
       
       // create HRS Term/Transfer Case and Reference Object
       Id RT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('HRS Termination Transfer Case Record Type').getRecordTypeId();
       Case TermTransferCase = new Case(AccountId=a1.id,
                              RecordTypeId= RT);
       insert TermTransferCase;
       
       Reference_HRS_Termination_Transfer__c TermTransfer = new Reference_HRS_Termination_Transfer__c(Case_Lookup__c = TermTransferCase.Id);
       insert TermTransfer;
       
       system.assertEquals(TermTransfer.Client_Start_Date__c, null);
       
       //Client Start Date is filled in on Insert of an Asset
       Asset asset884 = new Asset(Name='PAS 06 SUBMITTED',
       					Product_plan_Code__c='884',
       					Plan_Cancel_Date__c=null,
       					AccountId=a1.Id,
       					Start_Date__c= date.today());
       
       insert asset884;
       List<Reference_HRS_Termination_Transfer__c> refTerm = [SELECT Id, Client_Start_Date__c from Reference_HRS_Termination_Transfer__c WHERE id =: TermTransfer.id];
       system.assertEquals(date.today(), refTerm[0].Client_Start_Date__c);
 system.debug('LM termtransfer - ' +refTerm);      
       //when another asset is inserted, the more recent Start_Date should be used to populate Client Start Date
       Asset asset793 = new Asset(Name='PAS SUBMITTED',
       					Product_plan_Code__c='793',
       					Plan_Cancel_Date__c=null,
       					AccountId=a1.Id,
       					Start_Date__c= date.today()-3);
       					
       test.startTest();
       insert asset793;
       test.stopTest();
       List<Reference_HRS_Termination_Transfer__c> refTerm2 = [SELECT Client_Start_Date__c from Reference_HRS_Termination_Transfer__c WHERE id =: TermTransfer.id]; 
       system.assertEquals(1,refTerm2.size()); 
       system.assertEquals(date.today(),refTerm2[0].Client_Start_Date__c);
       
       //when multiple assets are inserted at one time, the Client Start Date should populate with the most recently dated one.
       List<Asset> assetList = new List<Asset>();
       Asset ast1 = new Asset(Name='PHRS ASO NPR', 
       					Product_plan_Code__c='1010',
       					Plan_Cancel_Date__c=null,
       					AccountId=a1.Id,
       					Start_Date__c= date.today()+3);
      
       Asset ast2 = new Asset(Name='PAYX BUS SOL',
       					Product_plan_Code__c='1029',
       					Plan_Cancel_Date__c=null, 
       					AccountId=a1.Id,
       					Start_Date__c= date.today()+4);
      
       Asset ast3 = new Asset(Name='PAS 06 SUBMITTED',
       					Product_plan_Code__c='884',
       					Plan_Cancel_Date__c=null,
       					AccountId=a1.Id,
       					Start_Date__c= date.today()-3);
      assetList.add(ast1);
      assetList.add(ast2);
      assetList.add(ast3);
      insert assetList;
      
      List<Asset> assets = [SELECT id, Start_Date__c, Product_Plan_Code__c FROM Asset WHERE Accountid =: a1.id];
     
      system.assertEquals(5, assets.size());
       	
       	List<Reference_HRS_Termination_Transfer__c> refTerm3 = [SELECT Client_Start_Date__c from Reference_HRS_Termination_Transfer__c WHERE id =: TermTransfer.id];
       	system.assertEquals(date.today()+4, refTerm3[0].Client_Start_Date__c);				
       
       //an Asset inserted with a Plan Cancel Date should not update the Client Start Date
       Asset asset1005 = new Asset(Name='ADVANTAGE PREMIER',
       					Product_plan_Code__c='1005',
       					Plan_Cancel_Date__c= date.today()+4,
       					AccountId=a1.Id,
       					Start_Date__c= date.today()+3);
       insert asset1005;
       List<Reference_HRS_Termination_Transfer__c> refTerm4 = [SELECT Client_Start_Date__c from Reference_HRS_Termination_Transfer__c WHERE id =: TermTransfer.id];
       system.assertEquals(date.today()+4, refTerm4[0].Client_Start_Date__c);
     
   }//end testPopulateClientStartDate

   private static void checkEvents(Id eventId1, String expectedResult1, Id eventId2, String expectedResult2) {
      Map<Id,Event> eventMap = new Map<Id,Event>([Select Id, HR_Solution_Cancel__c from Event where Id=:eventId1 or Id=:eventId2]);
      System.assertEquals(expectedResult1,eventMap.get(eventId1).HR_Solution_Cancel__c);
      System.assertEquals(expectedResult2,eventMap.get(eventId2).HR_Solution_Cancel__c);
   } // checkEvent

   private static void checkTasks(Id taskId1, String expectedResult1, Id taskId2, String expectedResult2) {
      Map<Id, Task> taskMap = new Map<Id,Task>([Select Id, HR_Solution_Cancel__c from Task where Id=:taskId1 or Id=:taskId2]);
      System.assertEquals(expectedResult1,taskMap.get(taskId1).HR_Solution_Cancel__c);
      System.assertEquals(expectedResult2,taskMap.get(taskId2).HR_Solution_Cancel__c);
   } // checkTask
   
	/* LM - backing code out per Leslie 11/3/16
	static testMethod void testUpdateAccount() {
		Account acct = new Account(Name='Test Acct');
      	insert acct;
      
	     Asset asst1 = new Asset(Name='Asset1',AccountId=acct.Id,Product_Plan_Code__c='CA-MMS_PAY', Start_Date__c = Date.TODAY());
	     insert asst1;
	     // Asset asst2 = new Asset(Name='Asset2',AccountId=acct.Id,Product_Plan_Code__c='CA-ADV', Plan_Cancel_Date__c = null, Plan_Lost_Reason__c);
	     // Asset asst3 = new Asset(Name='Asset3',AccountId=acct.Id,Product_Plan_Code__c='CA-BPR');
	     List<Account> accounts = new List<Account>();
	     accounts =  [SELECT Id, Reason_Lost__c, Lost_Date__c FROM Account WHERE Id =: acct.id];
	     System.assertEquals(null, accounts[0].Reason_Lost__c);
	     System.assertEquals(null, accounts[0].Lost_Date__c);
	     
	     Date cancelDate = Date.TODAY();
	     asst1.Plan_Cancel_Date__c = cancelDate.addDays(15);
	     asst1.Plan_Lost_Reason__c = 'Using new product.';
	     update asst1;
	     accounts =  [SELECT Id, Reason_Lost__c, Lost_Date__c FROM Account WHERE Id =: acct.id];
	     System.assertEquals('Using new product.', accounts[0].Reason_Lost__c);
	     System.assertNotEquals(null, accounts[0].Lost_Date__c);
	     
	     Asset asst2 = new Asset(Name='Asset2',AccountId=acct.Id,Product_Plan_Code__c='CA-ADV', Start_Date__c = Date.TODAY(), Plan_Cancel_Date__c = cancelDate.addDays(17), Plan_Lost_Reason__c = 'Too expensive.');
   		 insert asst2;
   		 accounts =  [SELECT Id, Reason_Lost__c, Lost_Date__c FROM Account WHERE Id =: acct.id];
	     System.assertEquals('Too expensive.', accounts[0].Reason_Lost__c);
	     System.assertNotEquals(null, accounts[0].Lost_Date__c);
   		
   		//make the asset Active again should clear the Lost Date and Lost Reason on the Account
   		asst2.Plan_Cancel_Date__c = null;
   		update asst2;
   		accounts =  [SELECT Id, Reason_Lost__c, Lost_Date__c FROM Account WHERE Id =: acct.id];
	     System.assertEquals(null, accounts[0].Reason_Lost__c);
	     System.assertEquals(null, accounts[0].Lost_Date__c);
   }*/
} // class AssetMethodsTest