/* 
   Test Methods for the NSSSalesMethods class.
   
  History
  -------
  03/16/2015 Dan Carmen      Created
  04/27/2015 Dan Carmen      Change to test methods based on opportunity splits being active
  01/21/2017 Cindy Freeman	 Added record types to accounts on insert so child parent lookup filter works
 */
@isTest
private class NSSSalesMethodsTest {
	
	public static String PROD_PAY='PAY';
   public static String PROD_401='401k';
	
	public static ProductGroupMapping__c[] setupProductGroupMappings() {
	   ProductGroupMapping__c[] pgms = new ProductGroupMapping__c[]{};
	         pgms.add(new ProductGroupMapping__c(Name=NSSSalesMethods.MAPPING_TYPE+'-'+PROD_PAY
                                            ,MappingType__c=NSSSalesMethods.MAPPING_TYPE
                                            ,Product_of_Interest__c=PROD_PAY
                                            ,Sales_Org__c=UserHelper.SO_CORE
                                            ,Sales_Org2__c=UserHelper.SO_MMS
                                            ,ProductType__c=PROD_PAY));
            pgms.add(new ProductGroupMapping__c(Name=NSSSalesMethods.MAPPING_TYPE+'-'+PROD_401
                                            ,MappingType__c=NSSSalesMethods.MAPPING_TYPE
                                            ,Product_of_Interest__c=PROD_401
                                            ,Sales_Org__c=UserHelper.SO_401
                                            ,Sales_Org2__c=null
                                            ,ProductType__c=PROD_401));
	   insert pgms;
	   return pgms;
	} // setupProductGroupMappings

   // test the insert of the NSS Client record
   static testMethod void testInsertClient() {
      // insert accounts to match to
      Account acct1 = new Account(Name='Test 1', AccountNumber='77-12345678');
      Account acct2 = new Account(Name='Test 2');
      Account acct3 = new Account(Name='Test 3');
      Account[] accts = new Account[]{acct1,acct2,acct3};
      insert accts;
      
      // we'll use this as the "bad id"
      Id acct3Id = acct3.Id;
      delete acct3;
      
      NSSSalesClient__c nssClt1 = new NSSSalesClient__c(ClientNumber__c='12345678',CompanyName__c='Test 3', OfficeNumber__c='77' );
      insert nssClt1;
      
      nssClt1 = [Select Id, Name, CheckedForDupe__c, ClientNumber__c, CompanyName__c
                       ,IsDuplicate__c, OfficeNumber__c, ParentClientRecord__c
                   From NSSSalesClient__c
                  Where Id = :nssClt1.Id];
      System.assertEquals(acct1.AccountNumber, nssClt1.Name);
      System.assertEquals(true, nssClt1.CheckedForDupe__c);
      System.assertEquals(false, nssClt1.IsDuplicate__c);
      System.assertEquals(null, nssClt1.ParentClientRecord__c);
      
      // a link should have been made to the account record
      NSSSalesAcctLink__c acctLink1 = [Select Id, Name, BranchClientMatch__c, ImportMatch__c, NSSSalesClient__c, Account__c
                                         From NSSSalesAcctLink__c
                                        Where NSSSalesClient__c = :nssClt1.Id
                                          and Account__c = :acct1.Id];
      System.assertEquals(true, acctLink1.BranchClientMatch__c);
      System.assertEquals(false, acctLink1.ImportMatch__c);
      
      // insert a duplicate client record
      NSSSalesClient__c nssClt2 = new NSSSalesClient__c(ClientNumber__c='12345678',CompanyName__c='Test 4', OfficeNumber__c='77' );
      insert nssClt2;
      nssClt2 = [Select Id, Name, CheckedForDupe__c, ClientNumber__c, CompanyName__c
                       ,IsDuplicate__c, OfficeNumber__c, ParentClientRecord__c
                   From NSSSalesClient__c
                  Where Id = :nssClt2.Id];
      System.assertEquals(acct1.AccountNumber, nssClt2.Name);
      System.assertEquals(true, nssClt2.CheckedForDupe__c);
      // verify it's marked as a duplicate
      System.assertEquals(true, nssClt2.IsDuplicate__c);
      System.assertEquals(nssClt1.Id, nssClt2.ParentClientRecord__c);
      
      // there should not be link from nssClt2
      System.assertEquals(0,[select count() from NSSSalesAcctLink__c where NSSSalesClient__c = :nssClt2.Id]);
      
      // insert a couple of NSS Sales Acct records
      NSSSalesAcct__c nsa1 = new NSSSalesAcct__c(OfficeNumber__c=nssClt1.OfficeNumber__c, ClientNumber__c=nssClt1.ClientNumber__c
                                                ,AccountId__c=acct1.Id, NSRName__c='Test Name1');
      NSSSalesAcct__c nsa2 = new NSSSalesAcct__c(OfficeNumber__c=nssClt1.OfficeNumber__c, ClientNumber__c=nssClt1.ClientNumber__c
                                                ,AccountId__c=acct2.Id, NSRName__c='Test Name2');
      NSSSalesAcct__c nsa2b = new NSSSalesAcct__c(OfficeNumber__c=nssClt1.OfficeNumber__c, ClientNumber__c=nssClt1.ClientNumber__c
                                                ,AccountId__c=acct2.Id, NSRName__c='Test Name2b');
      NSSSalesAcct__c nsa3 = new NSSSalesAcct__c(OfficeNumber__c=nssClt1.OfficeNumber__c, ClientNumber__c=nssClt1.ClientNumber__c
                                                ,AccountId__c=acct3Id, NSRName__c='Test Name3');
      NSSSalesAcct__c nsa4 = new NSSSalesAcct__c(OfficeNumber__c='44', ClientNumber__c='A1234'
                                                ,AccountId__c=acct3Id, NSRName__c='Test Name4');
      NSSSalesAcct__c[] salesAccts = new NSSSalesAcct__c[]{nsa1,nsa2,nsa2b,nsa3,nsa4};
      
      System.debug('testInsertClient before insert salesAccts');
      insert salesAccts;
      System.debug('testInsertClient after insert salesAccts');
      
      nsa1 = [Select Id, Name, AccountId__c, AccountIdChecked__c, AccountIdIsValid__c, NSSSalesClient__c from NSSSalesAcct__c where Id=:nsa1.Id];
      System.assertEquals(true,nsa1.AccountIdChecked__c);
      System.assertEquals(true,nsa1.AccountIdIsValid__c);
      System.assertEquals(nssClt1.Id,nsa1.NSSSalesClient__c);
      
      nsa2 = [Select Id, Name, AccountId__c, AccountIdChecked__c, AccountIdIsValid__c, NSSSalesClient__c from NSSSalesAcct__c where Id=:nsa2.Id];
      System.assertEquals(true,nsa2.AccountIdChecked__c);
      System.assertEquals(true,nsa2.AccountIdIsValid__c);
      System.assertEquals(nssClt1.Id,nsa2.NSSSalesClient__c);

      nsa3 = [Select Id, Name, AccountId__c, AccountIdChecked__c, AccountIdIsValid__c, NSSSalesClient__c from NSSSalesAcct__c where Id=:nsa3.Id];
      System.assertEquals(true,nsa3.AccountIdChecked__c);
      System.assertEquals(false,nsa3.AccountIdIsValid__c);
      System.assertEquals(nssClt1.Id,nsa3.NSSSalesClient__c);

      nsa4 = [Select Id, Name, AccountId__c, AccountIdChecked__c, AccountIdIsValid__c, NSSSalesClient__c from NSSSalesAcct__c where Id=:nsa4.Id];
      System.assertEquals(true,nsa4.AccountIdChecked__c);
      System.assertEquals(false,nsa4.AccountIdIsValid__c);
      System.assertEquals(null,nsa4.NSSSalesClient__c);

      acctLink1 = [Select Id, Name, BranchClientMatch__c, ImportMatch__c, NSSSalesClient__c, Account__c
                                         From NSSSalesAcctLink__c
                                        Where NSSSalesClient__c = :nssClt1.Id
                                          and Account__c = :acct1.Id];
      System.assertEquals(true, acctLink1.BranchClientMatch__c);
      // there should now be an import match on this same record
      System.assertEquals(true, acctLink1.ImportMatch__c);
      
      // should still be one even though we inserted two records for this account id
      NSSSalesAcctLink__c acctLink2 = [Select Id, Name, BranchClientMatch__c, ImportMatch__c, NSSSalesClient__c, Account__c
                                         From NSSSalesAcctLink__c
                                        Where NSSSalesClient__c = :nssClt1.Id
                                          and Account__c = :acct2.Id];
      System.assertEquals(false, acctLink2.BranchClientMatch__c);
      System.assertEquals(true, acctLink2.ImportMatch__c);
      
      // test inserting product records
      SalesOrg__c[] salesOrgs = UserHelperTest.setupSalesOrgSetting();
      ProductGroupMapping__c[] pgms = setupProductGroupMappings();
      
      // get NSRs
      User[] outboundNSRs = ProspectOwnershipMethodsTest.getOutboundNSRs(2);
      User nsr1=outboundNSRs[0];
      User nsr2=outboundNSRs[1];
      
      // create opportunities
      SalesOrg__c soPay = SalesOrg__c.getInstance(UserHelper.SO_CORE);
      SalesOrg__c so401 = SalesOrg__c.getInstance(UserHelper.SO_401);
      Schema.Recordtypeinfo payOppRT = RecordTypeHelper.getRecordType(soPAY.OpptyRecordTypeName__c, ObjectHelper.OBJECT_OPPTY);
      Schema.Recordtypeinfo hrsOppRT = RecordTypeHelper.getRecordType(so401.OpptyRecordTypeName__c, ObjectHelper.OBJECT_OPPTY);
      
      Opportunity opp1 = new Opportunity(AccountId=acct1.Id, RecordTypeId=payOppRT.getRecordTypeId(), Name='Test Opp1', StageName='Pending', CloseDate=Date.today());
      Opportunity opp2 = new Opportunity(AccountId=acct1.Id, RecordTypeId=hrsOppRT.getRecordTypeId(), Name='Test Opp2', StageName='Pending', CloseDate=Date.today());

      Opportunity opp3 = new Opportunity(AccountId=acct2.Id, RecordTypeId=payOppRT.getRecordTypeId(), Name='Test Opp3', StageName='Pending', CloseDate=Date.today());
      Opportunity opp4 = new Opportunity(AccountId=acct2.Id, RecordTypeId=hrsOppRT.getRecordTypeId(), Name='Test Opp4', StageName='Pending', CloseDate=Date.today());
      Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3,opp4};
      insert opps;

      Prospect_Ownership__c po1 = new Prospect_Ownership__c(Prospect_Client__c=acct1.Id, NSR_Name__c=nsr1.Id, Ownership_Status__c='Commission Only'
                                          ,CommissionStart__c=Date.today().addMonths(-1), CommissionEnd__c=Date.today().addMonths(2)
                                          ,NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                          ,Opportunity__c=opp1.Id);
      Prospect_Ownership__c po2 = new Prospect_Ownership__c(Prospect_Client__c=acct1.Id, NSR_Name__c=nsr2.Id, Ownership_Status__c='Commission Only'
                                          ,CommissionStart__c=Date.today().addMonths(-1), CommissionEnd__c=Date.today().addMonths(2)
                                          ,NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                          ,Opportunity__c=opp2.Id);
      Prospect_Ownership__c po3 = new Prospect_Ownership__c(Prospect_Client__c=acct2.Id, NSR_Name__c=nsr1.Id, Ownership_Status__c='Commission Only'
                                          ,CommissionStart__c=Date.today().addMonths(-1), CommissionEnd__c=Date.today().addMonths(2)
                                          ,NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                          ,Opportunity__c=opp3.Id);
                                          
      // both NSRs will be on the same opportunity
      Prospect_Ownership__c po4 = new Prospect_Ownership__c(Prospect_Client__c=acct2.Id, NSR_Name__c=nsr1.Id, Ownership_Status__c='Commission Only'
                                          ,CommissionStart__c=Date.today().addMonths(-1), CommissionEnd__c=Date.today().addMonths(2)
                                          ,NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                          ,Opportunity__c=opp4.Id);
      Prospect_Ownership__c po5 = new Prospect_Ownership__c(Prospect_Client__c=acct2.Id, NSR_Name__c=nsr2.Id, Ownership_Status__c='Commission Only'
                                          ,CommissionStart__c=Date.today().addMonths(-1), CommissionEnd__c=Date.today().addMonths(2)
                                          ,NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                          ,Opportunity__c=opp4.Id);
      Prospect_Ownership__c[] pos = new Prospect_Ownership__c[]{po1,po2,po3,po4,po5};
      insert pos;
                                          
      OpportunityTeamMember otm1 = new OpportunityTeamMember(OpportunityId=opp1.Id, UserId=nsr1.Id, TeamMemberRole='NSR', Prospect_Ownership__c=po1.Id,NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND);
      OpportunityTeamMember otm2 = new OpportunityTeamMember(OpportunityId=opp2.Id, UserId=nsr2.Id, TeamMemberRole='NSR', Prospect_Ownership__c=po2.Id,NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND);
      OpportunityTeamMember otm3 = new OpportunityTeamMember(OpportunityId=opp3.Id, UserId=nsr1.Id, TeamMemberRole='NSR', Prospect_Ownership__c=po3.Id,NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND);
      OpportunityTeamMember otm4 = new OpportunityTeamMember(OpportunityId=opp4.Id, UserId=nsr1.Id, TeamMemberRole='NSR', Prospect_Ownership__c=po4.Id,NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND);
      OpportunityTeamMember otm5 = new OpportunityTeamMember(OpportunityId=opp4.Id, UserId=nsr2.Id, TeamMemberRole='NSR', Prospect_Ownership__c=po5.Id,NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND);
      OpportunityTeamMember[] otms = new OpportunityTeamMember[]{otm1,otm2,otm3,otm4,otm5};
      insert otms;
      
      User[] salesReps = [Select Id, Name, HR_Person_Id__c from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS limit 2];
      User rep1 = salesReps[0];
      User rep2 = salesReps[1];
      
      NSSSalesProduct__c nsp1 = new NSSSalesProduct__c(OfficeNumber__c=nssClt1.OfficeNumber__c, ClientNumber__c=nssClt1.ClientNumber__c
                                         ,FirstRunDate__c=Date.today(), ProductCode__c=pgms[0].Product_of_Interest__c,WinDiscountImport__c='10%'
                                         ,SalesRepPersonId__c=rep1.HR_Person_Id__c, SalesRepName__c=rep1.Name);
      
      NSSSalesProduct__c nsp2 = new NSSSalesProduct__c(OfficeNumber__c=nssClt1.OfficeNumber__c, ClientNumber__c=nssClt1.ClientNumber__c
                                         ,FirstRunDate__c=Date.today(), ProductCode__c=pgms[0].Product_of_Interest__c,WinDiscountImport__c='11.5%'
                                         ,SalesRepPersonId__c=rep1.HR_Person_Id__c, SalesRepName__c=rep1.Name);
      
      NSSSalesProduct__c nsp3 = new NSSSalesProduct__c(OfficeNumber__c=nssClt1.OfficeNumber__c, ClientNumber__c=nssClt1.ClientNumber__c
                                         ,FirstRunDate__c=Date.today(), ProductCode__c=pgms[0].Product_of_Interest__c
                                         ,SalesRepPersonId__c=rep2.HR_Person_Id__c, SalesRepName__c=rep2.Name);
      
      NSSSalesProduct__c nsp4 = new NSSSalesProduct__c(OfficeNumber__c=nssClt1.OfficeNumber__c, ClientNumber__c=nssClt1.ClientNumber__c
                                         ,FirstRunDate__c=Date.today(), ProductCode__c=pgms[0].Product_of_Interest__c
                                         ,SalesRepPersonId__c=rep2.HR_Person_Id__c, SalesRepName__c=rep2.Name);
      NSSSalesProduct__c[] prods = new NSSSalesProduct__c[]{nsp1,nsp2,nsp3,nsp4};
      insert prods;
      
      System.assertEquals(true,[select count() from NSSSalesOppLink__c] > 0);
      
      NSSSalesMethods.PROCESS_MULTI_ID=true;
      NSSSalesMethods.PROCESS_MULTI_SAME_FEIN=true;
      
      Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
      Account testParent = new Account(Name='Test Sales Parent',AccountNumber='12-TEST0000',recordtypeId = acctCorert.getRecordTypeId());
      insert testParent;
      
      // create child accounts
      Account acctChild1 = new Account(Name='Test ParentId',AccountNumber='12-TEST1111',ParentId=acct1.Id,recordtypeId = acctCorert.getRecordTypeId());
      Account acctChild2 = new Account(Name='Test Sales Parent',AccountNumber='12-TEST2222',SalesParent__c=testParent.Id,recordtypeId = acctCorert.getRecordTypeId());
      Account acctFein1 = new Account(Name='Test FEIN 1', AccountNumber='12-TEST3333', FEIN_Parent_ID__c='45678',recordtypeId = acctCorert.getRecordTypeId());
      Account acctFein2 = new Account(Name='Test FEIN 2', AccountNumber='12-TEST3344', FEIN_Parent_ID__c='45678',recordtypeId = acctCorert.getRecordTypeId());
      Account[] childAccts = new Account[]{acctChild1,acctChild2,acctFein1,acctFein2};
      insert childAccts;
      
      NSSSalesAcct__c nsa10 = new NSSSalesAcct__c(OfficeNumber__c=nssClt1.OfficeNumber__c, ClientNumber__c=nssClt1.ClientNumber__c
                                                ,AccountId__c=acctChild1.Id, NSRName__c='Test Name1');
      NSSSalesAcct__c nsa11 = new NSSSalesAcct__c(OfficeNumber__c=nssClt1.OfficeNumber__c, ClientNumber__c=nssClt1.ClientNumber__c
                                                ,AccountId__c=acctChild2.Id, NSRName__c='Test Name1');
      NSSSalesAcct__c nsa12 = new NSSSalesAcct__c(OfficeNumber__c=nssClt1.OfficeNumber__c, ClientNumber__c=nssClt1.ClientNumber__c
                                                ,AccountId__c=acctFein1.Id, NSRName__c='Test Name1');
      NSSSalesAcct__c[] childNsas = new NSSSalesAcct__c[]{nsa10,nsa11,nsa12};
      insert childNsas;

      
   } // testInsertClient
   

   static testMethod void checkClientDuplicates() {
      NSSSalesClient__c nssClt1 = new NSSSalesClient__c(ClientNumber__c='12345678',CompanyName__c='Test 3', OfficeNumber__c='78' );
      NSSSalesClient__c nssClt2 = new NSSSalesClient__c(ClientNumber__c='12345678',CompanyName__c='Test 4', OfficeNumber__c='78' );
      NSSSalesClient__c nssClt3 = new NSSSalesClient__c(ClientNumber__c='12345678',CompanyName__c='Test 5', OfficeNumber__c='78' );
      NSSSalesClient__c[] nssClts = new NSSSalesClient__c[]{nssClt1, nssClt2, nssClt3};
      insert nssClts;
      
      // only one record will be checked for a duplicate
      System.assertEquals(1, [select count() from NSSSalesClient__c where Name='78-12345678' and CheckedForDupe__c=true and IsDuplicate__c=false]);
      // the other two will not be checked.
      System.assertEquals(2, [select count() from NSSSalesClient__c where Name='78-12345678' and CheckedForDupe__c=false]);

      // save again
      update nssClts;

      System.assertEquals(1, [select count() from NSSSalesClient__c where Name='78-12345678' and CheckedForDupe__c=true and IsDuplicate__c=false]);
      // the other two will not be checked.
      System.assertEquals(2, [select count() from NSSSalesClient__c where Name='78-12345678' and CheckedForDupe__c=true and IsDuplicate__c=true]);

   } // checkClientDuplicates
} // class NSSSalesMethodsTest