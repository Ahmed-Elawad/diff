// test for HoldOutManagerController

/* 

	History
	--------
	
	5/19/2015 Josh Cartwright 	created
	9/10/2015 Josh Cartwright - added testAssignHoldOut 
	9/14/2015 Josh Cartwright - added testassign hold out for referral contact
	3/28/2015 Josh Cartwright - updated test class to accept standard set controller 
	6/04/2020 Jake Hinds		Adding Referral Account Hold out Reason

*/	
@isTest
private class HoldOutControllerTest {

   @testSetup
   public static void setupData() {
      TriggerMethodsTest.createTriggerSetting('AccountBefore', true, false, false, false, new String[]{'ZipCheckOwner','AccountJunctionMethods'});
      TriggerMethodsTest.createTriggerSetting('AccountAfter', false, true, false, false, new String[]{'ZipCheckOwner','AccountJunctionMethods'});
      TriggerMethodsTest.createTriggerSetting('ReferralAccountBefore', true, false, false, false, new String[]{'ZipCheckOwner'});
      TriggerMethodsTest.createTriggerSetting('ReferralContactBefore', true, false, false, false, new String[]{'ZipCheckOwner'});
      TriggerMethodsTest.saveSetupClasses();
   } // setupData
    
   public static User dsa;
   public static User rep1;
   public static User rep2;
     
   
   public static Referral_Account__c refAcct1 = createTestRefAcct('refAcct1');    	
   public static Referral_Account__c refAcct2 = createTestRefAcct('refAcct2');   	
   public static Referral_Account__c refAcct3 = createTestRefAcct('refAcct3');   	
   public static Referral_Account__c[] refaccts = new Referral_Account__c []{refAcct1, refAcct2,refAcct3}; 

   public static Referral_Contact__c refCntct1;   	
   public static Referral_Contact__c refCntct2;
   public static Referral_Contact__c refCntct3;
   public static Referral_Contact__c[] refCntcts;
  
   public static Account Acct1 = createTestAcct('acct1');   	
   public static Account Acct2 = createTestAcct('acct2');   	
   public static Account Acct3 = createTestAcct('acct3');   	
   public static Account [] accts = new Account []{acct1, acct2,acct3}; 
   
   public static Account acct4; 

   public static Contact cntct1;   	
   public static Contact cntct2;
   public static Contact cntct3;
   public static Contact[] cntcts; 
   
   
   	
   public static void setupRefData() {
   	 UserHelperTest.selectDsaAndReps(); 
   	
   	dsa = UserHelperTest.v_dsa;
   	
   	rep1 = UserHelperTest.v_reps[0];

    rep2 = UserHelperTest.v_reps[1];
   	

   	insert refAccts;  
   	
   	refCntct1 = createTestRefCntct(refAcct1.id, rep1.Id, 'refCntct1');   	
   	refCntct2  = createTestRefCntct(refAcct2.id, rep1.id, 'refCntct2');
	refCntct3 = createTestRefCntct(refAcct3.id, rep2.id, 'refCntct3');
   	refCntcts = new Referral_Contact__c []{refCntct1, refCntct2, refCntct3};
   	insert refCntcts; 
   	
   } // setupRefData
   
   public static void setupStndData() {
   	insert accts;  
   	
   	cntct1 = createTestCntct(acct1.id, rep1.Id, 'cntct1', 'lName1');   	
   	cntct2  = createTestCntct(acct2.id, rep1.id, 'cntct2', 'lName1');
	cntct3 = createTestCntct(acct3.id, rep2.id, 'cntct3', 'lName1');
   	cntcts = new Contact []{cntct1, cntct2, cntct3};
   	insert cntcts; 
   	
   } // setupStndData
 

   static testMethod void testReassign() {
      runTest('testReassign');
   }//testReassign
   
   static testMethod void testReassignQueueable(){
   		runTest('testReassignQueueable'); 
   }//testReassignQueueable
   
   static testMethod void testRemoveHoldOut() {
      runTest('testRemoveHoldOut');
   }//testRemoveHoldOut
   
   static testMethod void testZipFilter(){
   	  runTest('testZipFilter');
   }//testZipFilter 
   
   static testMethod void testAssignHoldOut(){
   	  runTest('testAssignHoldOut');
   }//testAssignHoldOut
   
  static void runTest(String testType) {
  	setupRefData();
  	setupStndData();
   	   	
   	system.assertEquals(2,[select count()from Referral_Contact__c where OwnerID = :rep1.id]);
   	system.assertEquals(2,[select count()from Contact where OwnerID = :rep1.id]);
   	
   	refAcct1.OwnerID = rep1.id; 
	update refAcct1; 
		
	refAcct1.Hold_Out__c = true; 
	refAcct1.Referral_Source_Business_Type__c = 'broker'; 
	update refAcct1; 
	
	acct1.OwnerID = rep1.id; 
	acct1.hold_out__c = true; 
	acct1.Permanent_Hold_Out_Description__c = 'ADMIN'; 
	update acct1; 

	list<Referral_Account__c> refAcctList = [select name, ownerid, Referral_Source_Business_Type__c, id from Referral_Account__c where ownerID = : rep1.id]; 
	list<Account> acctList = [select name, ownerid, Permanent_Hold_Out_Description__c, id from Account where ownerID = : rep1.id]; 

	
	system.assert (refAcctList.size() == 1);
	system.assert (acctList.size()==1); 
   	
   	System.runAs(dsa) {
   		
   	   HoldOutController hoc = new HoldOutController();
	   hoc.objectselect = HoldOutController.REF_CTCT; 	   
	   hoc.selectedRepID = rep1.Id; 	
	   
    system.assertEquals(true,hoc.isRefCtct);  	   
	   	
	system.assertequals(false, hoc.hasDisplayList); 
				
	hoc.referralTypeFilter = '100 Broker';
		
	hoc.getRepHoldoutRecords();	
		   
	system.assertequals(true, hoc.hasDisplayList); 
//	system.assertequals(false, hoc.largeDisplayList); 
	
	system.assertequals(0,apexpages.getmessages().size()) ; 	
	
	hoc.displayList[0].selected = true;
	
	hoc.addtoSelectMap(); 
	
	system.assert(hoc.hasSelectedMessage);  
	
	system.assert(hoc.selectedMessage != null);
	
	hoc.reAssignHoldOut(); 	
	
	system.assertequals(1,apexpages.getmessages().size()) ; 
	
	
	system.assert(!hoc.selectedList.isEmpty());
	system.assert(hoc.hasSelectedList == true);
	system.assert(hoc.selectedList.size() == 1); 
//	system.assert(hoc.columnSize == 1); 
	
	
	hoc.objectselect = HoldOutController.REF_ACCT;
	hoc.selectedRepID = rep1.Id;	
	hoc.rsbtFilter = 'broker'; 
	hoc.usefilter = true; 
	
	hoc.getRepHoldoutRecords();	
	system.assertequals(true, hoc.isRefAcct); 
	
	system.assertequals(true, hoc.hasDisplayList); 
	
	hoc.displayList[0].selected = true; 
	
	hoc.reAssignHoldOut(); 	
	
	system.assertequals(2,apexpages.getmessages().size()) ; 
	
	
	system.assert(!hoc.selectedList.isEmpty());
	system.assert(hoc.selectedList.size() == 1); 

	hoc.selectedRepID = rep1.Id;
	hoc.objectselect = HoldOutController.ACCT;
	hoc.pHoldOutDescFilter = 'ADMIN'; 
	hoc.usefilter = true; 
	
		
	hoc.getRepHoldoutRecords();	
	system.assertequals(true, hoc.isAcct); 
	
	system.assertequals(true, hoc.hasDisplayList); 
	
	hoc.displayList[0].selected = true; 
	
	hoc.reAssignHoldOut(); 	
	
	system.assertequals(3,apexpages.getmessages().size()) ; 
	
	
	system.assert(!hoc.selectedList.isEmpty());
	system.assert(hoc.selectedList.size() == 1); 	

/*	hoc.objectselect = HoldOutController.CTCT;
		
	hoc.getRepHoldoutRecords();	
	system.assertequals(true, hoc.isCtct); 
	
	system.assertequals(true, hoc.hasDisplayList); 
	
	hoc.displayList[0].selected = true; 
	
	hoc.reAssignHoldOut(); 	
	
	system.assertequals(4,apexpages.getmessages().size()) ; 
	
	
	system.assert(!hoc.selectedList.isEmpty());
	system.assert(hoc.selectedList.size() == 1); 		
	*/

	hoc.objectselect = HoldOutController.REF_CTCT; 	
	hoc.getRepHoldoutRecords();
	hoc.displayList[0].selected = true; 
    hoc.reAssignHoldOut(); 	
    hoc.usefilter = false; 
    	

	
	if (testType == 'testReassign') {
	system.assert(hoc.selectReassignUser); 
	hoc.cancelReassign();
	
	system.assert(!hoc.selectReassignUser);
	system.assert(!hoc.selectAll); 
	
	hoc.reAssignHoldOut();
	
	system.assertequals(4,apexpages.getmessages().size()) ;  		
	
	hoc.displayList[0].selected = true; 
	
	hoc.reAssignHoldOut(); 
	
	system.assertequals(4,apexpages.getmessages().size()) ;  		
		
	hoc.reAssignRecords();
	system.assertequals(5, apexpages.getmessages().size()) ;  		
	
    hoc.reAssignSelectedRepId = rep2.Id; 
    
    system.assert(hoc.hasSelectedRepID); 
    
	hoc.reAssignRecords(); 
	
    list<Referral_Contact__c> refCntctList = [select id, OwnerId, Referral_Type__c from Referral_Contact__c where Name = :'refCntct1'];

	
	system.assertEquals(refCntctList[0].ownerID, rep2.ID);
   	system.assertEquals(hoc.selectReassignUser, false);
   	
   	hoc.selectedRepID = rep1.Id;		
	hoc.objectselect = HoldOutController.REF_ACCT; 	
	hoc.getRepHoldoutRecords();			
	system.assert(!hoc.displayList.isEmpty());
	system.assert(hoc.isRefAcct); 	
	hoc.displayList[0].selected = true;	
	hoc.newPHoldOutDesc = 'ADMIN';
	system.assertequals(rep1.id, refAcct1.OwnerId);
	
	system.assertequals(5,apexpages.getmessages().size()); 
	
	hoc.reAssignHoldOut(); 	

	hoc.reAssignSelectedRepId = rep2.Id;
	
	hoc.reAssignRecords(); 
	
	list<Referral_Account__c> refAcctReassignList = [select id, OwnerId, Referral_Source_Business_Type__c from Referral_Account__c where Name = :'refAcct1'];

	
	system.assertEquals(refAcctReassignList[0].ownerID, rep2.ID);
   	system.assertEquals(hoc.selectReassignUser, false);
   	
	acct4 = createTestAcct('acct4');    
	insert acct4; 	
   	
   	hoc.selectedRepID = rep1.Id;
   	acct4.ownerid = rep1.id; 
   	acct4.Permanent_Hold_Out_Description__c = '';
   	update acct4; 
   	
   	acct4.hold_Out__c = true; 
	acct4.Hold_Out_Expiration__c = Date.today().addDays(+1); 
   	
   	update acct4; 

   			
	hoc.objectselect = HoldOutController.ACCT; 	
	hoc.getRepHoldoutRecords();			
	system.assert(!hoc.displayList.isEmpty());
	system.assert(hoc.isAcct); 
	hoc.displayList[0].selected = true;
	hoc.displayList[1].selected = true; 
	hoc.newPHoldOutDesc = 'ADMIN';	
	system.assertequals(rep1.id, acct1.OwnerId);
	
	system.assertequals(5,apexpages.getmessages().size()); 
	
	hoc.reAssignHoldOut(); 	
	
	system.assert(!hoc.isAssignAcct); 	
	list <SelectOption> testPHoldoutDescOptionsList = hoc.getNewPermHoldOut();	
	system.assert(testPHoldoutDescOptionsList.size()!=0);
	
	
//	system.assert (hoc.hasNoAccessList ==true);

	hoc.reAssignSelectedRepId = rep2.Id;
	
	hoc.queryAcct.Hold_Out_Expiration__c = Date.today().addDays(+1); 
	
	hoc.reAssignRecords(); 

	
	list<Account> acctReassignList = [select id, OwnerId, Permanent_Hold_Out_Description__c from Account where Name = :'acct1'];

	
	system.assertEquals(acctReassignList[0].ownerID, rep2.ID);
   	system.assertEquals(hoc.selectReassignUser, false);   	
		
   	hoc.selectedRepID = rep1.Id;		
/*
	hoc.objectselect = HoldOutController.CTCT; 	
	hoc.getRepHoldoutRecords();			
	system.assert(!hoc.displayList.isEmpty());
	system.assert(acctReassignList[0].Permanent_Hold_Out_Description__c != null);
	
	
	acct1.Permanent_Hold_Out_Description__c = 'ADMIN'; 
	acct2.Permanent_Hold_Out_Description__c =''; 
	update acct1;
	update acct2; 	
	
	
	hoc.reAssignHoldOut();
	

	
	
	
	system.assert(hoc.isCtct); 
	hoc.displayList[0].selected = true;	
	system.assertequals(rep1.id, cntct1.OwnerId);
	
	system.assertequals(6,apexpages.getmessages().size()); 
	
	hoc.reAssignHoldOut(); 	

	hoc.reAssignSelectedRepId = rep2.Id;
	
	hoc.reAssignRecords(); 
	
	list<Contact> ctctReassignList = [select id, OwnerId from Contact where FirstName = :'cntct1'];

	
	system.assertEquals(acctReassignList[0].ownerID, rep2.ID);
   	system.assertEquals(hoc.selectReassignUser, false);   	
*/		
		
	} // if (testType == 'testReassign')
	
		else if (testType == 'testReassignQueueable'){
	//test reassignqueueable - new 3-29-2017
   	HoldOutcontroller.QUEUEABLE_LIMIT = 1; 
   	
	hoc.cancelReassign();
   	
	acct4 = createTestAcct('acct4');    
	insert acct4; 	
	   	
   	hoc.selectedRepID = rep1.Id;
   	acct4.ownerid = rep1.id; 
   	acct4.Permanent_Hold_Out_Description__c = 'Advantage Rep';	
   	acct4.hold_Out__c = true; 
   	
   	update acct4; 

   			
	hoc.objectselect = HoldOutController.ACCT; 	
	hoc.getRepHoldoutRecords();			
	hoc.displayList[0].selected = true;
	hoc.displayList[1].selected = true; 
	hoc.newPHoldOutDesc = 'ADMIN';	
		
	hoc.reAssignHoldOut(); 	

//	testUpdatedList.addAll((sObject[])hoc.displaylist); 	
	
	hoc.reAssignSelectedRepId = rep2.Id;
	
	test.startTest();
	 
	hoc.reAssignRecords(); 
	
	test.stopTest(); 
	
	list<Account> acctReassignList = [select id, OwnerId, Permanent_Hold_Out_Description__c from Account where Name = :'acct1'];

 
	system.assertEquals(acctReassignList[0].ownerID, rep2.ID);
   	system.assertEquals(hoc.selectReassignUser, false);   	
   	
		
   	hoc.selectedRepID = rep1.Id;	


		
	}//testReassignQueueable
	
	else if (testType == 'testRemoveHoldOut'){
	
		system.assert(hoc.hasDisplayList);
		hoc.removeHoldOut();
		
	    list<Referral_Contact__c> refCntctList = [select id, Hold_Out__c, OwnerId from Referral_Contact__c where Name = :'refCntct1'];
	    
	    system.assert(refCntctList.size() == 1);
	    
	    system.assertequals(false, hoc.selectReassignUser);
		
		system.assertequals(false, refCntctList[0].Hold_Out__c);

		hoc.objectselect = HoldOutController.REF_ACCT; 	
		
		hoc.selectedRepID = rep1.id; 
		
		hoc.getRepHoldoutRecords();	
		
		hoc.displayList[0].selected = true; 		
		
		hoc.removeHoldOut();
		
		list<Referral_Account__c> refAcctRemoveList = [select id, hold_out__c,hold_out_reason__c, OwnerID from Referral_Account__c where name =: 'refAcct1'];
		
		system.assert(refAcctRemoveList.size()==1);

	    system.assertequals(false, hoc.selectReassignUser);
		
		system.assertequals(false, refAcctRemoveList[0].Hold_Out__c);
		system.assertequals(null, refAcctRemoveList[0].Hold_Out_Reason__c);	
					
		
		hoc.objectSelect = HoldOutController.Acct;
		
		hoc.selectedRepID = rep1.id; 
		
		hoc.getRepHoldOutRecords(); 
		
		system.assert(hoc.hasDisplayList); 
				
		system.assert (hoc.isAcct); 		
		
		hoc.displayList[0].selected = true; 
		hoc.removeHoldOut(); 
		
		list<Account> acctRemoveList = [select id, hold_Out__c, OwnerID from Account where name = 'Acct1']; 
		
		system.assertequals(false, acctRemoveList[0].hold_Out__c);
		
		
		
		
		
		
	}//(testType == 'testRemoveHoldOut')
		 
	else if (testType == 'testZipFilter')	{
	hoc.toggleUseFilter();
	
	system.assert(hoc.useFilter);

	hoc.toggleUseFilter();
	
	system.assert(!hoc.useFilter);
	
	hoc.toggleUseFilter();
	
	system.assert(hoc.useFilter);		
	
	hoc.zipLow = null;	
	hoc.zipHigh = null;	
	
	hoc.applyFilter();
	system.assert(hoc.zipLow == '00000');
	system.assert(hoc.zipHigh == '99999');
		 
   	
   	hoc.zipHigh = '10001';
   	hoc.zipLow = '10000'; 
   	hoc.applyFilter();
   	
//  system.assertEquals(true,hoc.applyFilter());
	system.assertequals(3, apexpages.getmessages().size()) ;  		
	system.assert(!hoc.hasDisplayList);
   	
   	hoc.zipHigh = '20000';
   	hoc.zipLow = '10000';
   	hoc.applyFilter();
   	
  	system.assert(hoc.hasDisplayList);
  	
  	hoc.ziphigh = '534';
//  	system.assert(!hoc.applyFilter());
	hoc.applyFilter();
	system.assertequals(4, apexpages.getmessages().size()) ;  		
	
  	hoc.zipLow = 'asdfa'; 
  //	system.assert(!hoc.applyFilter()); 
  	hoc.applyFilter();
  	system.assertequals(5, apexpages.getmessages().size()) ;  	
  	
  	list <SelectOption> testOptionsList = hoc.getOptions();	
  	
  	system.assert(!testOptionsList.isEmpty());
  	
  	hoc.objectselect = HoldOutController.REF_ACCT; 


  	list <SelectOption> testRSBTOptionsList = hoc.getRSBTOptions();	
 	//test
 	hoc.toggleUseFilter();
	
	system.assert(!hoc.useFilter);
	
	hoc.toggleUseFilter();
	
	system.assert(hoc.useFilter);	//end	
   	hoc.applyFilter();
   	
  	system.assert(hoc.hasDisplayList);
   	
   	
  	
  	system.assert(!testRSBTOptionsList.isEmpty());

  	hoc.objectselect = HoldOutController.ACCT; 	
 	system.assert (hoc.isAcct);  	
  	hoc.pHoldOutDescFilter = 'ADMIN';
  	
  	hoc.toggleUseFilter();  	
  	  	
  	list <SelectOption> testPHoldoutDescOptionsList = hoc.getPermHoldOut();	
   	hoc.applyFilter();
  	
  	system.assert(!testPHoldoutDescOptionsList.isEmpty());  	
  	  	
  	list <SelectOption> testObjectList = hoc.getObject();	
  	
  	system.assert(!testObjectList.isEmpty());
  	
  	
  	
  	
  	
  	
  	
		
	}   //testType == 'testZipFilter'	
      	
	 
	
  	 	} // System.runAs(dsa)     
    }//testReassign
    
    static testMethod void testHierarchy() {
       ManageZipAssignControllerTest.setupOrgUnits();
       Org_Unit__c dist = ManageZipAssignControllerTest.districts[0];
       Org_Unit__c zone = OrgUnitMethods.getOrgUnits(null, null, new Id[]{dist.Parent__r.Id}, null, null)[0];
       Org_Unit__c div = zone.Parent__r;
       User runningUser = [Select Id, Name from User where IsActive=true and Profile.Name=:Utilities.PROF_SYS_ADMIN limit 1];
   	   UserHelperTest.selectDsaAndReps(); 
   	   Org_Unit_User_Link__c[] newLinks = new Org_Unit_User_Link__c[]{};
   	   for (User rep : UserHelperTest.v_reps) {
   	      newLinks.add(new Org_Unit_User_Link__c(Org_Unit__c=dist.Id, User__c=rep.Id));
   	   }
   	   insert newLinks;
   	   
   	   dist.RepUserRoleId__c = UserHelperTest.v_reps[0].UserRoleId;
   	   dist.UserRoleId__c = UserHelperTest.v_dsa.UserRoleId;
   	   update dist;
   	   setupRefData();
   	   setupStndData();
   	   	
   	   System.debug('testHierarchy rep1='+rep1);
   	   
	   	
	   	refCntct1 = [select Id, Name, Hold_Out__c, OwnerId, Owner.UserRoleId, Owner.Name, User_Lookup__c, User_Lookup__r.Name, User_Lookup__r.UserRoleId from Referral_Contact__c where Id=:refCntct1.Id];
	   	System.debug('refCntct1='+refCntct1+' User_Lookup__r='+refCntct1.User_Lookup__r);
	   	System.debug('refCntct1='+refCntct1+' owner='+refCntct1.Owner);
	   	System.assertEquals(rep1.UserRoleId, refCntct1.User_Lookup__r.UserRoleId);
	   	
        system.assertEquals(3,[select count() from Referral_Contact__c where Hold_Out__c=true and User_Lookup__r.UserRoleId = :rep1.UserRoleId]);
   	   
   	   
   	  System.runAs(runningUser) {
   	    rep2.IsActive=false;
   	    update rep2;
   	  }
   	   
   	   System.runAs(runningUser) {
   	      HoldOutController hoc = new HoldOutController();
   	      
   	      system.assertEquals(false,hoc.hasRepOptions);
          system.assertEquals(true,hoc.mzac.isSystemAdmin);
          hoc.mzac.searchZa.Sales_Org__c = dist.Sales_Org__c;
          hoc.mzac.setSalesOrg();
          hoc.salesOrgSelected();
          hoc.mzac.selectedZoneId = zone.Id;
          hoc.zoneSelected();
          hoc.mzac.selectedDistrictId = dist.Id;
          hoc.districtSelected();
          system.assertEquals(true, hoc.mzac.selectedDistrictOrgUnit != null);
   	      system.assertEquals(true,hoc.hasRepOptions);   
   	       	       
   	      
   	      hoc.mzac.selectedReassignZoneId = zone.Id;
   	      hoc.reassignSalesOrgSelecteD();   	         	      
   	      hoc.mzac.selectedReassignDistrictId = dist.Id;
   	      hoc.reAssignDistrictSelected();
   	      system.assertEquals(true,hoc.hasReassignRepOptions);
   	      
   	      hoc.cancelReAssign(); 
   	      
   	      Test.startTest();
   	      hoc.objectselect = HoldOutController.REF_ACCT;
   	      
   	      hoc.mzac.setSalesOrg();
          hoc.mzac.selectedZoneId = zone.Id;
          hoc.zoneSelected();
          hoc.mzac.selectedDistrictId = dist.Id;
          hoc.districtSelected();
          system.assertEquals(true, hoc.mzac.selectedDistrictOrgUnit != null);
   	      system.assertEquals(true,hoc.hasRepOptions);   

          hoc.objectselect = HoldOutController.ACCT;
   	      
   	      hoc.mzac.setSalesOrg();
          hoc.mzac.selectedZoneId = zone.Id;
          hoc.zoneSelected();
          hoc.mzac.selectedDistrictId = dist.Id;
          hoc.districtSelected();
          system.assertEquals(true, hoc.mzac.selectedDistrictOrgUnit != null);
   	      system.assertEquals(true,hoc.hasRepOptions);      	
   	      
   	      hoc.objectselect = HoldOutController.CTCT;
   	      
   	      hoc.mzac.setSalesOrg();
          hoc.mzac.selectedZoneId = zone.Id;
          hoc.zoneSelected();
          hoc.mzac.selectedDistrictId = dist.Id;
          hoc.districtSelected();
          system.assertEquals(true, hoc.mzac.selectedDistrictOrgUnit != null);
   	      system.assertEquals(true,hoc.hasRepOptions);         
   	      Test.stopTest();

   	      
   	       	      
   	      
   	      
          
   	   } // System.runAs
   	   
    } // testHierarchy
    
    
   static testMethod void testAsignHoldOut() {
   	//test ref accounts and ref contacts 
   	
   	setupRefData(); 	
   	User sysAdmin = [select id from user where isactive = true and profile.name='System Administrator' limit 1];	 
   	refAcct1.Hold_Out__c = true;
    refAcct1.Hold_Out_Reason__c = 'ADMIN';
   	refAcct1.BypassHoldOut__c = true;  
   	refAcct1.ownerID = rep1.id; 
   	refAcct2.ownerID = sysAdmin.id;    	
    refAcct3.Hold_Out__c = false;  
    refAcct3.ownerID = rep1.id; 
   	update refAccts;  
   	
   	
   	 //test Referral Accounts Assign start: 
     ApexPages.StandardSetController sc = new ApexPages.StandardSetController(refAccts);
     sc.setSelected(refAccts); 
     
     
     
     system.runas(dsa){  
     HoldOutController hoc = new HoldOutController(sc);

     system.assertEquals(true,hoc.recordsFound);         
     system.assertEquals(true,hoc.hasNoAccessList);
     system.assert(!hoc.displayList.isEmpty());
     system.assert(hoc.displayList.size() == 1); 
     system.assert(hoc.noAccessList.size()==2); 
     system.assert(hoc.isRefAcct == true); 
     system.assertEquals (hoc.displayList[0].refAcct.Name, refAcct3.name );
     
      list<Referral_Account__c> noAccessList = [select id, hold_Out__c, OwnerId from Referral_Account__c where Name =: 'refAcct1'];
 //     list <User> rep1List = [select id from User where User =: rep1];
    //  system.assertEquals (noAccessList[0].ownerid, rep1List[0].id); 
     
     
     
     system.assertEquals (hoc.noAccessList[0].noAccessReason, 'Hold Out Exists'); 
     system.assertEquals (hoc.noAccessList[0].refAcct.ownerid, rep1.id); 
     
     hoc.reassignSelectedRepID = rep2.id; 
     
     list<Referral_Account__c> refAcct1List = [select id, hold_Out__c,Hold_Out_Reason__c, OwnerId from Referral_Account__c where Name =: 'refAcct1'];
     
     system.assert(refAcct1List.size() ==1);
     system.assert(refAcct1List[0].Hold_Out__c == true);  
     system.assert(refAcct1List[0].Hold_Out_Reason__c == 'ADMIN');     
	 hoc.newPHoldOutDesc = 'ADMIN';
     hoc.assignHoldOut(); 
     
     list<Referral_Account__c> refAcctList = [select id, OwnerId from Referral_Account__c where Name = :'refAcct3'];
     
     system.assertEquals (rep2.id, refAcctList[0].OwnerID); 

     //End Test Referral Accounts Assign
     }// runas(dsa)  
     
 	 //test Referral Contact Assign start: 
	refCntct1.Hold_Out__c = true;    	 
	refCntct1.BypassHoldOut__c = true;
	refCntct1.ownerid = rep1.id;   		   	
	refCntct2.ownerID = sysAdmin.id;
	refCntct3.Hold_Out__c = false; 
	refCntct3.ownerID = rep1.id; 
	update refCntcts;
 	 
 	 
     ApexPages.StandardSetController RCsc = new ApexPages.StandardSetController(refCntcts);  
     RCsc.setSelected(refCntcts);
     	   	
 	system.runas(dsa){  
     HoldOutController hoc = new HoldOutController(RCsc);    
     system.assertEquals(true,hoc.recordsFound);         
     system.assertEquals(true,hoc.hasNoAccessList);
     system.assert(!hoc.displayList.isEmpty());
     system.assert(hoc.displayList.size() == 1); 
     system.assert(hoc.noAccessList.size()==2); 
     system.assert(hoc.isRefCtct == true); 

     list<Referral_Contact__c> RCNoAccessList = [select id, hold_Out__c, OwnerId from Referral_Contact__c where Name =: 'refCntct1'];
          
     system.assertEquals (hoc.noAccessList[0].noAccessReason, 'Hold Out Exists'); 
     system.assertEquals (hoc.noAccessList[0].refCtct.ownerid, rep1.id); 
     
     hoc.reassignSelectedRepID = rep2.id; 
     list<Referral_Contact__c> refCntct1List = [select id, hold_Out__c, OwnerId from Referral_Contact__c where Name =: 'refCntct1'];
     
     system.assert(refCntct1List.size() ==1);
     system.assert(refCntct1List[0].Hold_Out__c == true);     

     hoc.assignHoldOut(); 
     
     list<Referral_Contact__c> refCntctList = [select id, OwnerId from Referral_Contact__c where Name = :'refCntct3'];
     
     system.assertEquals (rep2.id, refCntctList[0].OwnerID);      
      //End Test Referral Contact Assign
       
 	}//runasDSA
 	
 	//test Account Assign start: 
 	setupStndData();
   	Acct1.Hold_Out__c = true;
   	Acct1.Bypass_Hold_Out__c = true;  
   	Acct1.ownerID = rep1.id; 
   	Acct2.ownerID = sysAdmin.id;    	
    Acct3.Hold_Out__c = false;  
    Acct3.ownerID = rep1.id; 
   	update Accts;  
   	
   	
   	
   	
   	 //test Referral Accounts Assign start: 
     ApexPages.StandardSetController acctSC = new ApexPages.StandardSetController(Accts);
     acctSC.setSelected(Accts); 
     
     
     
     system.runas(dsa){  
     HoldOutController hoc = new HoldOutController(acctSC);
     
     hoc.newPHoldOutDesc = 'Advantage Rep';
     hoc.assignHoldOut(); 
	 
     system.assert(hoc.isAcct == true); 
     system.assert(hoc.isAssignAcct);
     
	list<Account> acctAssignList = [select id, OwnerId, Permanent_Hold_Out_Description__c from Account where Name = :'acct1'];
	
	system.assert(acctAssignList[0].Permanent_Hold_Out_Description__c != null);
	
	list <SelectOption> testNewPHoldOutDesList = hoc.getNewPermHoldOut();
	 	
	system.assert(testNewPHoldOutDesList.size()!=0);
 

	 //End Test Accounts Assign
 	
 	} // run as DSA 
 	
   } // testAsignHoldOut
    
    
	
	static Referral_Account__c createTestRefAcct(String refAcctName){
        return new Referral_Account__c	(name = refAcctName                                   
                                        ,Street_Address_1__c = '911 Panorama Trail South'
                                        ,City__c = 'Rochester'
                                        ,State_Province__c = 'NY'
                                        ,Referral_Source_Business_Type__c = 'Broker'
                                        ,Zip_Postal_Code__c = '14586');
                                        
    } //createTestRefAcct   
    static Referral_Contact__c createTestRefCntct(id refAcctId, id rcOwnerId, String rcName){
        return new Referral_Contact__c(name = rcName                                       
                                        ,Referral_Account__c = refAcctId
                                        ,Hold_Out__c = true
                                        ,ByPassHoldout__c = true
                                        ,OwnerId = rcOwnerId
                                        ,Mailing_Street__c = '123'
                                        ,Mailing_City__c = 'Rochester'
                                        ,Mailing_State__c = 'NY'
                                        ,Mailing_Postal_Code__c = '14514'
                                        ,Referral_Type__c = '100 Broker'
                                        ,Mailing_Country__c = 'US');
    }//createTestRefCntct
    
    
    static Account createTestAcct(String acctName){
        return new Account	(name = acctName                                   
                                        ,ShippingStreet = '911 Panorama Trail South'
                                        ,ShippingCity = 'Rochester'
                                        ,ShippingState = 'NY'
                                        ,Permanent_Hold_Out_Description__c = 'ADMIN'
                                        ,ShippingPostalCode = '14586');
                                        
    } //createTestAcct   
    static Contact createTestCntct(id acctId, id cOwnerId, String cFName,  String cLName){
        return new Contact(FirstName = cFName
        								,LastName = cLNAme	                                       
                                        ,AccountId = acctId
                                        ,Hold_Out__c = true
                                        ,ByPassHoldout__c = true
                                        ,OwnerId = cOwnerId
                                        ,MailingStreet = '123'
                                        ,MailingCity = 'Rochester'
                                        ,MailingState = 'NY'
                                        ,MailingPostalCode = '14514'
                                        ,MailingCountry = 'US');
    }//createTestRefCntct
  
 /*   static User createTestUser (String firstName, String lastName, boolean isActive ){
    	return new User (firstname = firstName
    					,lastname = lastName
    					,sales_org__c = 'Pay'
    						,isActive = isActive);
    }//createTestUser*/
    
}//HoldOutControllerTest