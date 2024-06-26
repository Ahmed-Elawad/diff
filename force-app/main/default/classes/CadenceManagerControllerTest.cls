/* 
* TestMethod for the CadenceManagerController
*
* History
* ------------------
05/21/2020 Dan Carmen         Created
09/17/2020 Jermaine Stukes    Updated
10/10/2023 Dan Carmen         Update Cadence filter to use name instead of id.

*/
@isTest
public class CadenceManagerControllerTest {
   @testSetup
   public static void setupData() {
      ManageZipAssignControllerTest.setupOrgUnits();
      CadenceUpdateTest.setupTestCadence();
   } // setupData

   static testMethod void testCadence() {
      Account acct01 = new Account(Name='Account01', ShippingPostalCode='12345');
      Account acct02 = new Account(Name='Account02', ShippingPostalCode='12345');
      Account acct03 = new Account(Name='Account03', ShippingPostalCode='12345');
      Account acct04 = new Account(Name='Account04', ShippingPostalCode='12346');
      Account acct05 = new Account(Name='Account05', ShippingPostalCode='12346');
      Account acct06 = new Account(Name='Account06', ShippingPostalCode='12346');
      Account acct07 = new Account(Name='Account07', ShippingPostalCode='12347');
      Account acct08 = new Account(Name='Account08', ShippingPostalCode='12347');
      Account acct09 = new Account(Name='Account09', ShippingPostalCode='12347');
      Account acct10 = new Account(Name='Account10', ShippingPostalCode='12347');
      Account acct11 = new Account(Name='Account11', ShippingPostalCode='12347');
      Account acct12 = new Account(Name='Account12', ShippingPostalCode='12347');
      Account acct13 = new Account(Name='Account13', ShippingPostalCode='12347');
      //ZipCheckOwner.SKIP_TRIGGERS=true;
      Account[] accts = new Account[]{acct01,acct02,acct03,acct04,acct05,acct06,acct07,acct08,acct09,acct10,acct11,acct12,acct13};
      insert accts;
       
      Cadence__c cadence = CadenceUpdateTest.getTestCadence();
      User runningUser = UserHelper.getRunningUser();
      User reassignUser = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 1];
       
      Cadence_Assignment_Record__c car01 = new Cadence_Assignment_Record__c(Name='car01', CadenceObject__c = acct01.Id, Cadence__c=cadence.Id, Sales_Program__c = 'TestProgramA', Cadence_Owner__c=runningUser.Id);
      Cadence_Assignment_Record__c car02 = new Cadence_Assignment_Record__c(Name='car02', CadenceObject__c = acct02.Id, Cadence__c=cadence.Id, Sales_Program__c = 'TestProgramA', Cadence_Owner__c=runningUser.Id);
      Cadence_Assignment_Record__c car03 = new Cadence_Assignment_Record__c(Name='car03', CadenceObject__c = acct03.Id, Cadence__c=cadence.Id, Sales_Program__c = 'TestProgramA', Cadence_Owner__c=runningUser.Id);
      Cadence_Assignment_Record__c car04 = new Cadence_Assignment_Record__c(Name='car04', CadenceObject__c = acct04.Id, Cadence__c=cadence.Id, Sales_Program__c = 'TestProgramA', Cadence_Owner__c=runningUser.Id);
      Cadence_Assignment_Record__c car05 = new Cadence_Assignment_Record__c(Name='car05', CadenceObject__c = acct05.Id, Cadence__c=cadence.Id, Sales_Program__c = 'TestProgramA', Cadence_Owner__c=runningUser.Id);
      Cadence_Assignment_Record__c car06 = new Cadence_Assignment_Record__c(Name='car06', CadenceObject__c = acct06.Id, Cadence__c=cadence.Id, Sales_Program__c = 'TestProgramB', Cadence_Owner__c=runningUser.Id);
      Cadence_Assignment_Record__c car07 = new Cadence_Assignment_Record__c(Name='car07', CadenceObject__c = acct07.Id, Cadence__c=cadence.Id, Sales_Program__c = 'TestProgramB', Cadence_Owner__c=runningUser.Id);
      Cadence_Assignment_Record__c car08 = new Cadence_Assignment_Record__c(Name='car08', CadenceObject__c = acct08.Id, Cadence__c=cadence.Id, Sales_Program__c = 'TestProgramB', Cadence_Owner__c=runningUser.Id);
      Cadence_Assignment_Record__c car09 = new Cadence_Assignment_Record__c(Name='car09', CadenceObject__c = acct09.Id, Cadence__c=cadence.Id, Sales_Program__c = 'TestProgramB', Cadence_Owner__c=runningUser.Id);
      Cadence_Assignment_Record__c car10 = new Cadence_Assignment_Record__c(Name='car10', CadenceObject__c = acct10.Id, Cadence__c=cadence.Id, Sales_Program__c = 'TestProgramC', Cadence_Owner__c=runningUser.Id);
      Cadence_Assignment_Record__c car11 = new Cadence_Assignment_Record__c(Name='car11', CadenceObject__c = acct11.Id, Cadence__c=cadence.Id, Sales_Program__c = 'TestProgramC', Cadence_Owner__c=runningUser.Id);
      Cadence_Assignment_Record__c car12 = new Cadence_Assignment_Record__c(Name='car12', CadenceObject__c = acct12.Id, Cadence__c=cadence.Id, Sales_Program__c = 'TestProgramC', Cadence_Owner__c=runningUser.Id);
      Cadence_Assignment_Record__c car13 = new Cadence_Assignment_Record__c(Name='car13', CadenceObject__c = acct13.Id, Cadence__c=cadence.Id, Sales_Program__c = 'TestProgramC', Cadence_Owner__c=runningUser.Id);
      Cadence_Assignment_Record__c[] cars = new Cadence_Assignment_Record__c[]{car01,car02,car03,car04,car05,car06,car07,car08,car09,car10,car11,car12,car13};
      insert cars;

      CadenceManagerController.RECS_PER_PAGE=5;
      CadenceManagerController cmc = new CadenceManagerController();
      cmc.selectedRepId = runningUser.Id;
      cmc.repSelected();
      System.assertEquals(5,cmc.displayList.size());
      System.assertEquals(3,cmc.numOfPages);
      System.assertEquals(13,cmc.tpController.getResultSize());
      cmc.next();
      System.assertEquals(5,cmc.displayList.size());
      cmc.next();
      System.assertEquals(3,cmc.displayList.size());
      cmc.firstPage();
      System.assertEquals(5,cmc.displayList.size());
      cmc.lastPage();
      System.assertEquals(3,cmc.displayList.size());
      cmc.previous();
      cmc.previous();
      System.assertEquals(5,cmc.displayList.size());
       
      // set different filters
      System.assertEquals(3,cmc.filterStartedOptions.size()); 
      System.assertEquals(CadenceManagerController.FILTER_NONE,cmc.filterStartedSelection);
       
      cmc.filterZipLow = '12345';
      cmc.filterZipHigh = '12346';
      cmc.applyFilter();
      System.assertEquals(6,cmc.tpController.getResultSize());
       
      cmc.clearFilters();
      cmc.filterZipLow = '12347';
      cmc.applyFilter();
      System.assertEquals(7,cmc.tpController.getResultSize());
       
       cmc.clearFilters();
       cmc.salesProgramSelected = 'TestProgramC';
       cmc.applyFilter();
       System.assertEquals(4,cmc.tpController.getResultSize());
       
      cmc.clearFilters();
      cmc.applyFilter();

      cmc.reassignTPs();
      // should stay since no records are selected
      System.assertEquals(CadenceManagerController.MODE_MAIN,cmc.screenMode);

      // select 5 of the records
      for (CadenceManagerController.TpWrap wrap : cmc.displayList) {
         wrap.selected=true;
      }
      cmc.reassignCARs();
      System.assertEquals(CadenceManagerController.MODE_REASSIGN,cmc.screenMode);
      System.assertEquals(5,cmc.selectedList.size());
      cmc.selectedReassignRepId=null;
      // this would be an error
      cmc.performReassign();
      System.assertEquals(CadenceManagerController.MODE_REASSIGN,cmc.screenMode);
      cmc.selectedReassignRepId=reassignUser.Id;
      cmc.performReassign();
      System.assertEquals(CadenceManagerController.MODE_MAIN,cmc.screenMode);

      
   } // testCadence
    
   static testMethod void testRepSelection() {
      // find a role that has a lot of reps
      AggregateResult[] results = [Select UserRoleId roleId, UserRole.Name roleName,  count(Id) nbrUsers
                                     From User
                                    Where IsActive=true
                                      And Job_Name__c=:UserHelper.JOB_REP
                                      And Sales_Org__c=:UserHelper.SO_401
                                     Group By UserRoleId,  UserRole.Name
                                     Order by count(Id) desc];
      // just use the first one
      System.assertEquals(true,results.size()>1);
      AggregateResult result = results[0];
      System.debug('testRepSelection result='+result);
      Id roleId = (Id)result.get('roleId');
      String roleName = (String)result.get('roleName');
      Integer nbrUsers = (Integer)result.get('nbrUsers');
      
      CadenceManagerController cmc = new CadenceManagerController();
      System.assertEquals(false,cmc.hasRepOptions);
      System.debug('testRepSelection mzac.selectedDistrictId='+cmc.mzac.selectedDistrictId);
      System.assertNotEquals(null, cmc.mzac.selectedDistrictId);
      
      // set the role so the reps can be selected
      Org_Unit__c district = new Org_Unit__c(Id=cmc.mzac.selectedDistrictId, RepUserRoleName__c=roleName,RepUserRoleId__c=roleId, OverrideRepUserRoleName__c=true );
      update district;
      
      cmc = new CadenceManagerController();
      System.assertEquals(true,cmc.hasRepOptions);
      

   } // testRepSelection
    
} // class CadenceManagerControllerTest