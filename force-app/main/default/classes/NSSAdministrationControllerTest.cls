/* 
 * Test methods for the NSSAdministrationController.
 *
 * History
 * -------
 * 11/20/2013 Dan Carmen   Created
   06/09/2016 Dan Carmen   Adjustment for tests failing in production
   01/17/2017 Cindy Freeman  tweak to profile name
   10/31/2018 Dan Carmen       Change for View State error
   12/27/2018 Dan Carmen       Changes for DialSource - qbdialer__Callback_Date_Time__c replacement
   11/14/2019 Dan Carmen       Remove qbdialer references
   01/29/2020 Dan Carmen       Adjustments to code so it will pass tests
   09/08/2020 Jake Hinds       Adding LIKE to core mgr query

 */
@isTest
private class NSSAdministrationControllerTest {

   // Test that a user who doesn't have access can't get into the form.
   static testMethod void testAccess() {
    System.debug('Label.JobNSR='+Label.JobNSR+' UserHelper.JOB_NSR='+UserHelper.JOB_NSR);
    // select a System Administrator
      User u = [Select Id, Name from User where Profile.Name = :Utilities.PROF_SYS_ADMIN and IsActive=true limit 1];
      System.runAs(u) {
         Test.SetCurrentPageReference(Page.NSSAdministration);
         NSSAdministrationController nac = new NSSAdministrationController();
         System.assertEquals(true,nac.hasFormAccess);
      } // System.runAs

      // select a non-system admin, non NSS user
      u = [Select Id, Name from User where Profile.Name LIKE :Utilities.PROF_CORE_MGR+'%' and IsActive=true limit 1];
      System.runAs(u) {
         Test.SetCurrentPageReference(Page.NSSAdministration);
         NSSAdministrationController nac = new NSSAdministrationController();
         System.assertEquals(false,nac.hasFormAccess);
      } // System.runAs
      
      // run as an NSR
      String likeName = UserHelper.PROF_NSS_OUTBOUND + '%';
      u = [Select Id, Name from User where (Profile.Name = :UserHelper.PROF_NSS_INBOUND or Profile.Name like :likeName) and IsActive=true limit 1 ];
      System.runAs(u) {
         Test.SetCurrentPageReference(Page.NSSAdministration);
         NSSAdministrationController nac = new NSSAdministrationController();
         System.assertEquals(false,nac.hasFormAccess);
      } // System.runAs

      // run as an NSS Supervisor/Manager
      u = null;
      // find roles that have children
      AggregateResult[] nbrRepsBySuper = getRepsBySuperQuery();

      for (AggregateResult result : nbrRepsBySuper) {
         Id userRoleId = (Id)nbrRepsBySuper[0].get('userRoleId');
         try {
            u = [Select Id, Name from User where IsActive=true and UserRoleId=:userRoleId limit 1];
            break;
         } catch (Exception e) {}
      }
      
      System.assertEquals(true, (u != null));
      
      System.runAs(u) {
         Test.SetCurrentPageReference(Page.NSSAdministration);
         NSSAdministrationController nac = new NSSAdministrationController();
         System.assertEquals(true,nac.hasFormAccess);
      } // System.runAs
      
   } // testNoAccess

   private static AggregateResult[] getRepsBySuperQuery() {
      String likeName = UserHelper.PROF_NSS_OUTBOUND + '%';
      AggregateResult[] nbrRepsBySuper = [select UserRole.ParentRoleId userRoleId, count(id) nbr_nsrs from User
                                           where IsActive=true
                                             //and Profile.Name = :UserHelper.PROF_NSS_OUTBOUND
                                             and Job_Name__c = :UserHelper.JOB_NSR
                                             and Profile.Name Like :likeName
                                             and Manager.IsActive=true
                                             and Manager.Profile.Name in :UserHelper.NSS_MGR_PROF_SET
                                             and Manager.Job_Name__c=:UserHelper.JOB_NSS_SUPER
                                           group by UserRole.ParentRoleId
                                           order by count(id) desc];
      return nbrRepsBySuper;
   } // getRepsBySuperQuery

    // Test the transfer of the records.
   static testMethod void testTransfer() {
      System.debug('Label.JobNSR='+Label.JobNSR);
    // create the settings
    LifeOfLeadSettings__c lols = ProspectOwnershipMethodsTest.createProspectingLols(UserHelper.SO_CORE, ProspectOwnerShipMethods.NSS_OUTBOUND);

    AggregateResult[] nbrRepsBySuper = getRepsBySuperQuery();

      // should be at least 2 returned
      System.assertEquals(true,(nbrRepsBySuper.size() > 1));
    
      Id userRoleId1 = (Id)nbrRepsBySuper[0].get('userRoleId');
      Id userRoleId2 = (Id)nbrRepsBySuper[1].get('userRoleId');
      //Id managerId1 = (Id)nbrRepsBySuper[0].get('managerId');
      //Id managerId2 = (Id)nbrRepsBySuper[1].get('managerId');

      // select 2 from one supervisor
      String likeName = UserHelper.PROF_NSS_OUTBOUND + '%';
      User[] outbounds = [Select Id, Name, UserRole.ParentRoleId from User where UserRole.ParentRoleId = :userRoleId1 and Profile.Name like :likeName and IsActive=true limit 2 ];
      User outbound1 = outbounds[0];
      User outbound2 = outbounds[1];
      //User outbound1 = [Select Id, Name, UserRole.ParentRoleId from User where ManagerId = :managerId1 and Profile.Name like :likeName and IsActive=true limit 1 ];
      //User outbound2 = [Select Id, Name, UserRole.ParentRoleId from User where ManagerId = :managerId1 and Profile.Name like :likeName and IsActive=true and id != :outbound1.Id limit 1 ];
      // select 1 from another supervisor
      User outbound3 = [Select Id, Name, UserRole.ParentRoleId, IsActive from User where UserRole.ParentRoleId = :userRoleId2 and Profile.Name like :likeName and IsActive=true and id != :outbound1.Id and id != :outbound2.Id and Job_Name__c=:UserHelper.JOB_NSR limit 1 ];
      // create lead and account/contact records with prospect ownership records
      User super1 = [Select Id, Name, UserRoleId from User where IsActive=true and UserRoleId=:userRoleId1 limit 1];
      User super2 = [Select Id, Name, UserRoleId from User where IsActive=true and UserRoleId=:userRoleId2 limit 1];
      
      Lead l1 = new Lead(LastName='TestLead1', Company='Test Lead Co1', PostalCode='12345', OwnerId=outbound1.Id);
      Lead l2 = new Lead(LastName='TestLead2', Company='Test Lead Co2', PostalCode='12345', OwnerId=outbound1.Id);
      Lead l3 = new Lead(LastName='TestLead3', Company='Test Lead Co3', PostalCode='12345', OwnerId=outbound2.Id);
      Lead[] leads = new Lead[]{l1,l2,l3};
      insert leads;
      
      Account a1 = new Account(Name='TestAcct1');
      Account a2 = new Account(Name='TestAcct2');
      Account[] accts = new Account[]{a1,a2};
      insert accts;
      
      Contact c1a = new Contact(LastName='TestContact1a', AccountId=a1.Id);
      Contact c1b = new Contact(LastName='TestContact1b', AccountId=a1.Id);
      Contact c2a = new Contact(LastName='TestContact2a', AccountId=a2.Id);
      Contact c2b = new Contact(LastName='TestContact2b', AccountId=a2.Id);
      Contact[] ctcts = new Contact[]{c1a,c1b,c2a,c2b};
      insert ctcts;

      // create tasks for callbacks
      DateTime callbackDT = Datetime.now().addDays(20);
      Task tsk1 = new Task(WhoId=l1.Id, Type=TaskHelper.CT_CALLBACK, ActivityDate=callbackDT.date(), ReminderDateTime=callbackDT, OwnerId=outbound1.Id);
      Task tsk2 = new Task(WhoId=l2.Id, Type=TaskHelper.CT_CALLBACK, ActivityDate=callbackDT.date(), ReminderDateTime=callbackDT, OwnerId=outbound1.Id);
      Task tsk3 = new Task(WhoId=c1a.Id, Type=TaskHelper.CT_CALLBACK, ActivityDate=callbackDT.date(), ReminderDateTime=callbackDT, OwnerId=outbound1.Id);
      Task tsk4 = new Task(WhoId=c2a.Id, Type=TaskHelper.CT_CALLBACK, ActivityDate=callbackDT.date(), ReminderDateTime=callbackDT, OwnerId=outbound1.Id);
      Task[] tsks = new Task[]{tsk1,tsk2,tsk3,tsk4};
      insert tsks;
      
      Date startDate = Date.today().addDays(-30);
      Prospect_Ownership__c po1 = new Prospect_Ownership__c(Lead__c=l1.Id,Lead_Company__c=l1.Lead_Company__c,NSS_Team__c='PAY',NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                        ,StartDate__c=startDate, ProspectingStart__c=startDate
                                        ,NSR_Name__c=outbound1.Id, Ownership_Status__c='Prospecting');
      Prospect_Ownership__c po2 = new Prospect_Ownership__c(Lead__c=l2.Id,Lead_Company__c=l2.Lead_Company__c,NSS_Team__c='PAY',NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                        ,StartDate__c=startDate, ProspectingStart__c=startDate
                                        ,NSR_Name__c=outbound1.Id, Ownership_Status__c='Prospecting');
      Prospect_Ownership__c po3 = new Prospect_Ownership__c(Prospect_Client__c=a1.Id,NSS_Team__c=UserHelper.SO_CORE,NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                        ,StartDate__c=startDate, ProspectingStart__c=startDate
                                        ,NSR_Name__c=outbound1.Id, Ownership_Status__c='Prospecting');
      Prospect_Ownership__c po4 = new Prospect_Ownership__c(Prospect_Client__c=a2.Id,NSS_Team__c='PAY',NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                        ,StartDate__c=startDate, ProspectingStart__c=startDate
                                        ,NSR_Name__c=outbound1.Id, Ownership_Status__c='Prospecting');
      Prospect_Ownership__c po5 = new Prospect_Ownership__c(Lead__c=l3.Id,Lead_Company__c=l3.Lead_Company__c,NSS_Team__c='PAY',NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                        ,StartDate__c=startDate, ProspectingStart__c=startDate
                                        ,NSR_Name__c=outbound2.Id, Ownership_Status__c='Prospecting');
      Prospect_Ownership__c[] pos = new Prospect_Ownership__c[]{po1,po2,po3,po4,po5};
      insert pos;

      // verify ownership
      System.assertEquals(4,[select count() from Prospect_Ownership__c where NSR_Name__c=:outbound1.Id and EndDate__c = null]);
      System.assertEquals(1,[select count() from Prospect_Ownership__c where NSR_Name__c=:outbound2.Id and EndDate__c = null]);

      User runningUser = [Select Id, Name from User where Id=:UserInfo.getUserId()];
      System.runAs(runningUser) {
      
      // inactive outbound2
      outbound2.IsActive = false;
      update outbound2;
      } // System.runAs
      
      // enter the form as the running user
      Test.SetCurrentPageReference(Page.NSSAdministration);
      NSSAdministrationController nac = new NSSAdministrationController();
      System.assertEquals(true,nac.hasFormAccess);
      System.assertEquals(true,nac.isSystemAdmin);
      System.assertEquals(false,nac.isSupervisor);
      
      System.assertEquals(true, nac.hasSupervisorOptions);
      // set the supervisor of the first user
      //User supervisor1 = superByRoleIdMap.get(outbound1.UserRole.ParentRoleId);
      nac.selectedSupervisorFrom = super1.Id; //managerId1;
      nac.supervisorFromChanged();
      
      System.assertEquals(true,nac.hasTransferFromOptions);
      nac.selectedTransferFrom = outbound1.Id;
      nac.transferFromChanged();
      
      System.assertEquals(true,nac.selectedFromSet);
      
      // verify there are filter options
      System.assertEquals(true, nac.filterOptions.size() > 0);
      
      // skip the rest of the test if this is set to true - for some reason this is failing in prod.
      //if (Label.NSSAdminControllerTest_Skip=='Y') {
      //   return;
      //}
      // verify there are records
      System.assertEquals(true,nac.hasDisplayList);
      System.assertEquals(4,nac.displayList.size());
      
      nac.next();
      nac.previous();
      nac.firstPage();
      nac.lastPage();
      Integer nbrPages = nac.numOfPages;
      

      // set to a bad filter
      nac.selectedFilterOption = 'BAD OPTION';
      nac.filterChanged();
      // should be nothing here now
      System.assertEquals(false,nac.hasDisplayList);
      // change back to ALL option
      nac.selectedFilterOption = NSSAdministrationController.ALL;
      nac.filterChanged();
      
      // verify there are records
      System.assertEquals(true,nac.hasDisplayList);
      System.assertEquals(4,nac.displayList.size());
      System.debug('testTransfer before supervisor change transferUserMap='+nac.transferUserMap.size());

      // set transfer to supervisor
      //User supervisor2 = superByRoleIdMap.get(outbound3.UserRole.ParentRoleId);
      nac.selectedSupervisorTo = super2.Id; //supervisor2.Id;
      nac.supervisorToChanged();

      System.debug('testTransfer after supervisor change transferUserMap='+nac.transferUserMap.size());
      
      System.assertEquals(true,nac.hasTransferToOptions);
      
      // select ALL users, then deselect
      nac.selectAllTransferTo = true;
      nac.changeSelectAllTransferTo();
      System.assertEquals(true,nac.selectedToSet);

      nac.selectAllTransferTo = false;
      nac.changeSelectAllTransferTo();
      System.assertEquals(false,nac.selectedToSet);
      
      // click the verify button - should fail since nothing selected.
      nac.verifyTransfer();
      System.assertEquals(true,nac.hasFormAccess);
      System.assertEquals(false,nac.showVerify);
      System.assertEquals(false,nac.showResults);
      
      // select the one user we want to transfer to
      nac.selectedTransferTo.add(outbound3.Id);
      System.assertEquals(true,nac.selectedToSet);
      
      // select all of the records
      nac.selectAllOption = true;
      nac.changeSelectAllOption();
      
      System.debug('testTransfer starting verify that should succeed');
      nac.verifyTransfer();
      System.assertEquals(true,nac.hasFormAccess);
      System.assertEquals(true,nac.showVerify);

      //System.assertEquals(false,nac.showResults);

      // verify the callbacks
     // System.assertEquals(4,[Select count() from Task where OwnerId=:outbound1.Id]);
      //System.assertEquals(0,[Select count() from Task where OwnerId=:outbound3.Id]);

      // perform the transfer.
      nac.initializeTransfer();
      // verify that the records attached to the first NSR are ended
      System.assertEquals(4,[select count() from Prospect_Ownership__c where NSR_Name__c=:outbound1.Id and EndDate__c != null]);
      // verify that 4 records are created for the third NSR
      System.assertEquals(4,[select count() from Prospect_Ownership__c where NSR_Name__c=:outbound3.Id and EndDate__c = null]);
      
      // verify the callbacks
     // System.assertEquals(0,[Select count() from Task where OwnerId=:outbound1.Id]);
    //  System.assertEquals(4,[Select count() from Task where OwnerId=:outbound3.Id]);
    
      NSSAdministrationController.OwnerWrapper ownWrap = new NSSAdministrationController.OwnerWrapper(po1);
      System.assertEquals(true, ownWrap.isLead);
      System.assertEquals(false, ownWrap.isAccount);
      System.assertEquals(false, ownWrap.selected);
      ownWrap.newUser = runningUser;
      Id sourceId = ownWrap.sourceId;
      String disposition = ownWrap.callDisposition;
      
      NSSAdministrationController.TransferToWrapper transWrap = new NSSAdministrationController.TransferToWrapper(runningUser);
      transWrap.ownerRecs = new List<NSSAdministrationController.OwnerWrapper>();
      
      nac.changeSelectAllTransferTo();
      nac.verifyTransfer();
      
      Map<Id,Prospect_Ownership__c> poMap = nac.getPOMap(new Id[]{po1.Id});
      nac.initializeTransfer();
      nac.saveTransferLog();
      
   } // testTransfer

   // Test the page navigation controls.
   static testMethod void testPageControls() {
      System.debug('Label.JobNSR='+Label.JobNSR);
      // create the settings
      LifeOfLeadSettings__c lols = ProspectOwnershipMethodsTest.createProspectingLols(UserHelper.SO_CORE, ProspectOwnerShipMethods.NSS_OUTBOUND);
      
      AggregateResult[] nbrRepsBySuper = getRepsBySuperQuery();
      // should be at least 2 returned
      System.assertEquals(true,(nbrRepsBySuper.size() > 1));
      
      //Id managerId1 = (Id)nbrRepsBySuper[0].get('managerId');
      Id userRoleId = (Id)nbrRepsBySuper[0].get('userRoleId');

      // select 2 from one supervisor
      //User outbound1 = [Select Id, Name, ManagerId, UserRole.ParentRoleId from User where ManagerId = :managerId1 and Job_Name__c = :UserHelper.JOB_NSR and IsActive=true limit 1 ];
      User outbound1 = [Select Id, Name, ManagerId, UserRole.ParentRoleId from User where UserRole.ParentRoleId = :userRoleId and Job_Name__c = :UserHelper.JOB_NSR and IsActive=true limit 1 ];

      User supervisor = [Select Id, Name, UserRoleId from User where IsActive=true and UserRoleId=:userRoleId and Job_Name__c=:UserHelper.JOB_NSS_SUPER and Profile.Name in :UserHelper.NSS_MGR_PROF_SET limit 1];
      System.assertNotEquals(null,supervisor,'Could not find a supervisor with the Job Name of Supervisor!');
      // select an outbound NSR
      //User outbound1 = [Select Id, Name, ManagerId from User where Profile.Name = :UserHelper.PROF_NSS_OUTBOUND and Manager.Profile.Name in :UserHelper.NSS_MGR_PROF_SET and IsActive=true and Manager.IsActive=true limit 1 ];

      // the number of records to create
      Integer numRecs = 25;
      Lead[] leads = new Lead[]{};
      for (Integer cnt=0; cnt<numRecs; cnt++) {
         leads.add(new Lead(LastName='TestLead'+cnt, Company='Test Lead Co'+cnt, PostalCode='12345', OwnerId=outbound1.Id));
      }
      insert leads;
      
      Date startDate = Date.today().addDays(-30);
      Prospect_Ownership__c[] pos = new Prospect_Ownership__c[]{};
      for (Lead ld : leads) {
         Prospect_Ownership__c po = new Prospect_Ownership__c(Lead__c=ld.Id,Lead_Company__c=ld.Lead_Company__c,NSS_Team__c='PAY',NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                        ,StartDate__c=startDate, ProspectingStart__c=startDate
                                        ,NSR_Name__c=outbound1.Id, Ownership_Status__c='Prospecting');
         pos.add(po);
      } // for (Lead
      insert pos;

      // reset the page count
      NSSAdministrationController.RECS_PER_PAGE=10;
      
      // enter the form as the running user
      Test.SetCurrentPageReference(Page.NSSAdministration);
      NSSAdministrationController nac = new NSSAdministrationController();
      System.assertEquals(true,nac.hasFormAccess);
      System.assertEquals(true,nac.isSystemAdmin);
      System.assertEquals(false,nac.isSupervisor);
      
      System.assertEquals(true, nac.hasSupervisorOptions);
      // set the supervisor of the first user
      nac.selectedSupervisorFrom = supervisor.Id; //outbound1.ManagerId;
      nac.supervisorFromChanged();
      
      System.assertEquals(true,nac.hasTransferFromOptions);
      nac.selectedTransferFrom = outbound1.Id;
      nac.transferFromChanged();

      // skip the rest of the test if this is set to true - for some reason this is failing in prod.
      //if (Label.NSSAdminControllerTest_Skip!='Y') {
      System.assertEquals(3,nac.numOfPages);
      System.assertEquals(false,nac.ownershipRecs.getHasPrevious());
      System.assertEquals(true,nac.ownershipRecs.getHasNext());
      // go to the next page
      nac.next();
      System.assertEquals(true,nac.ownershipRecs.getHasPrevious());
      System.assertEquals(true,nac.ownershipRecs.getHasNext());
      nac.next();
      // on the last page
      System.assertEquals(true,nac.ownershipRecs.getHasPrevious());
      System.assertEquals(false,nac.ownershipRecs.getHasNext());
      nac.firstPage();
      System.assertEquals(false,nac.ownershipRecs.getHasPrevious());
      System.assertEquals(true,nac.ownershipRecs.getHasNext());
      nac.lastPage();
      System.assertEquals(true,nac.ownershipRecs.getHasPrevious());
      System.assertEquals(false,nac.ownershipRecs.getHasNext());
      nac.previous();
      System.assertEquals(true,nac.ownershipRecs.getHasPrevious());
      System.assertEquals(true,nac.ownershipRecs.getHasNext());
      nac.previous();
      // back to the first page
      System.assertEquals(false,nac.ownershipRecs.getHasPrevious());
      System.assertEquals(true,nac.ownershipRecs.getHasNext());
      //} // if (Label.NSSAdminControllerTest_Skip!='Y'

      // don't do anything further
      nac.cancel();
      
      nac.verifyEndOwnership();
      nac.confirmEndOwnership();
      nac.cancelEndOwnership();
   } // testPageControls

    static testMethod void testMisc() {
      NSSAdministrationController nac = new NSSAdministrationController();
      Boolean check = nac.hasTransferToOptions;
      check = nac.selectedToSet;
      nac.transferToAllOrSelected = 'None';
      System.assertEquals(false,nac.hasDisplayList);
      nac.filterChanged();
      
   } // testMisc

} // class NSSAdministrationControllerTest