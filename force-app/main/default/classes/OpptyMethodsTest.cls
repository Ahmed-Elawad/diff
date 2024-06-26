/* 
* Test Methods for the OpptyMethods class
*
* History
* -------
10/11/2013 Dan Carmen      Created
03/12/2015 Dan Carmen      Additional methods for linking an opp to an account 
04/27/2015 Dan Carmen      Change to test methods based on opportunity splits being active
01/20/2016 Dan Carmen      Update account from fields on the opportunity (br-clt number, fed id) 
10/13/2016 Dan Carmen      When linking the Opportunity to the referral (based on the entry of the lead id to the referral), delete
any uncoverted lead.
04/27/2017 Cindy Freeman   changed user query to be more selective
10/09/2017 Jacob Hinds    added SalesEngineer test
10/25/2017 Dan Carmen       Changes for OpportunityType__c
11/28/2017 Jacob Hinds     adding peo/aso into defaultRT test.
01/23/2018 Dan Carmen       Fix for some test for Opportunity Type
04/10/2018 Jacob Hinds   adding testSetForecastProbabilityFromOppStage
07/17/2018 Jacob Hinds  Adding testReferralRunEffectiveSync to sync referral run effective to selling run effective
12/07/2018 Lynn Michels  remove sales engineer test
02/22/2018 Jacob Hinds    Adding payroll platform sync test
04/30/2019 Matt Fritschi   Added Switch owner to inactive user test
05/24/2019 Jacob Hinds    Adding account holdout extension method
06/13/2019 Brandon Vidro Added Send Not Sold Email To MyCorp Test
03/10/2020 Jacob Hinds    Adding PAY and MMS to payroll platform code
03/20/2020 Jacob Hinds    Commenting out PAY and MMS to payroll platform code
06/08/2020 Dan Carmen     Add SoldOppHoldOutReason__c field to HoldOut ExpirationDates
11/16/2020 Brandon Vidro  Added testUpdatePrimaryCompetition()
12/02/2020 Dan Carmen     Refactor code to use TriggerInterface
05/18/2021 Carrie Marciano Updated StageName to use OppStage labels
05/20/2021 josh cartwright updated test for checkopportunitytype2
06/21/2021 Carrie Marciano commented out code that updates recordtype based on payroll plaform for PEO and ASO.  this is now done in OpptyLineItem
01/26/2023 Jermaine Stukes  Updated inactive user test
06/20/2023 Shilpa           Added method processSendtoHBOppsTest
12/08/2023 Jaipal          Removed method testUpdatePrimaryCompetition as Primary_Competition_Level_1__c & Primary_Competition_Level_2__c fields are getting deleted as part of APR0152387
12/11/2023 Dan Carmen        Refactored code for IEUP logic
01/22/2024 Vinay          Added updateOnboardingFormatTest method.
02/27/2024 Carrie Marciano  Added method to test when P&C oppty closes that it closes related P&C Case and Reference P&C records
05/27/2024 Shilpa G      APR0168449: Updated method testAccountUpdateHoldout
*/
@isTest
private class OpptyMethodsTest {
    
    @testSetup
    static void setupData() {
        TriggerMethodsTest.createTriggerSetting('OpptyBefore', true, false, false, false, new String[]{'OpptyMethods'});
        TriggerMethodsTest.createTriggerSetting('OpptyAfter', false, true, false, false, new String[]{'OpptyMethods'});
        TriggerMethodsTest.saveSetupClasses();
        
        OpptyCheckJoinTest.setupRecordTypeSettingForOpps();
        UserHelperTest.setupSalesOrgSetting();
        RecordTypeHelperTest.setupRecordType();
        
    } // setupData 
    
    // Test the method to add an NSR to the sales team.
    static testMethod void testCheckSalesTeamforNSR() {
        // select an NSR
        User[] users = ProspectOwnershipMethodsTest.getOutboundNSRs(1);
        User nsr = users[0];
        // create an account and contact
        Account acct = new Account(Name='Test Acct');
        insert acct;
        Contact ctct = new Contact(AccountId=acct.Id, LastName='LastName');
        insert ctct;
        
        // create a prospect ownership record
        Prospect_Ownership__c po = new Prospect_Ownership__c(Prospect_Client__c=acct.Id, StartDate__c=Date.today().addDays(-30)
                                                             ,NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND, NSS_Team__c=UserHelper.SO_CORE);
        po.CommissionStart__c = Date.today().addDays(-30);
        po.CommissionEnd__c = Date.today().addDays(30);
        po.Ownership_Status__c = 'Lockout';
        po.NSR_Name__c = nsr.Id;
        insert po;
        
        Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, ObjectHelper.OBJECT_OPPTY);
        // create 2 opportunities - 1 within the commission dates, 1 outside of the dates
        Opportunity opp1 = new Opportunity(RecordTypeId=rt.getRecordTypeId(),AccountId=acct.Id, Name='Opp1',StageName='Pending', CloseDate=Date.today());
        Opportunity opp2 = new Opportunity(RecordTypeId=rt.getRecordTypeId(),AccountId=acct.Id, Name='Opp2',StageName='Pending', CloseDate=Date.today().addDays(60));
        Opportunity[] opps = new Opportunity[]{opp1,opp2};
            insert opps;
        
        // should be a team member on the first one
        System.assertEquals(1,[select count() from OpportunityTeamMember where OpportunityId=:opp1.Id and UserId=:nsr.Id]);
        // should not be one on the second one
        System.assertEquals(0,[select count() from OpportunityTeamMember where OpportunityId=:opp2.Id and UserId=:nsr.Id]);
        
    } // testCheckSalesTeamforNSR
    
    static testMethod void testGetTeamMembersByOpptyIdMap() {
        // create opportunities with team members.
        Account acct = new Account(Name='Test Acct');
        insert acct;
        
        Opportunity opp1 = new Opportunity(Name='Test Opp1', AccountId=acct.Id, CloseDate=Date.today().addDays(14), StageName='Pending');
        Opportunity opp2 = new Opportunity(Name='Test Opp2', AccountId=acct.Id, CloseDate=Date.today().addDays(14), StageName='Pending');
        Opportunity[] opps = new Opportunity[]{opp1,opp2};
            insert opps;
        
        //User[] users = [Select Id, Name from User where IsActive=true and Job_Name__c = :UserHelper.JOB_NSR limit 4];
        User[] users = ProspectOwnershipMethodsTest.getOutboundNSRs(4);
        // create team members
        OpportunityTeamMember otm1 = new OpportunityTeamMember(OpportunityId=opp1.Id, UserId=users[0].Id, TeamMemberRole=OpptyMethods.ROLE_NSR);
        OpportunityTeamMember otm2 = new OpportunityTeamMember(OpportunityId=opp1.Id, UserId=users[1].Id, TeamMemberRole=OpptyMethods.ROLE_NSR);
        OpportunityTeamMember otm3 = new OpportunityTeamMember(OpportunityId=opp2.Id, UserId=users[2].Id, TeamMemberRole=OpptyMethods.ROLE_NSR);
        OpportunityTeamMember otm4 = new OpportunityTeamMember(OpportunityId=opp2.Id, UserId=users[3].Id, TeamMemberRole=OpptyMethods.ROLE_NSR);
        OpportunityTeamMember[] otms = new OpportunityTeamMember[]{otm1,otm2,otm3,otm4};
            insert otms;
        
        Opportunity opp3 = new Opportunity(Name='Test Opp3', AccountId=acct.Id, CloseDate=Date.today().addDays(14), StageName='Pending');
        insert opp3;
        
        String[] teamRoles = Label.OppyTeamMemberToKeepWhenOwnerChanged.split(',');
        OpportunityTeamMember otm5 = new OpportunityTeamMember(OpportunityId=opp3.Id, UserId=users[3].Id, TeamMemberRole=teamRoles[0],Demo_date__c = Date.today().addmonths(1));
        insert otm5;
        
        Opportunity opp4 = new Opportunity(Name='Test Opp4', AccountId=acct.Id, CloseDate=Date.today().addDays(14), StageName='Pending');
        insert opp4;
        
        opp3.ownerid = users[0].id;
        update opp3;
        
        Map<Id,List<OpportunityTeamMember>> teamMembersByOpptyIdMap = OpptyMethods.getTeamMembersByOpptyIdMap(new Id[]{opp1.Id,opp2.Id});
        
        // the number of NSR team members for each opp
        Integer nbrOpp1Team = 0;
        Integer nbrOpp2Team = 0;
        for (OpportunityTeamMember otm : teamMembersByOpptyIdMap.get(opp1.Id)) {
            if (otm.TeamMemberRole == OpptyMethods.ROLE_NSR) {
                nbrOpp1Team++;
            }
        } // for
        System.assertEquals(2,nbrOpp1Team);
        for (OpportunityTeamMember otm : teamMembersByOpptyIdMap.get(opp2.Id)) {
            if (otm.TeamMemberRole == OpptyMethods.ROLE_NSR) {
                nbrOpp2Team++;
            }
        } // for
        System.assertEquals(2,nbrOpp2Team);
        
    } // testGetTeamMembersByOpptyIdMap
    
    static testMethod void testIsPayroll() {
        System.assertEquals(true,OpptyMethods.isPayroll(UserHelper.SO_CORE));
        System.assertEquals(true,OpptyMethods.isPayroll(UserHelper.SO_MMS));
        System.assertEquals(false,OpptyMethods.isPayroll(UserHelper.SO_401));
        System.assertEquals(false,OpptyMethods.isPayroll(null));
    } // testIsPayroll
    
    static testMethod void testCheckOpportunityTypes() {
        Account acct = new Account(Name='Test Acct');
        insert acct;
        
        Schema.RecordTypeInfo rtCore = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, ObjectHelper.OBJECT_OPPTY);
        Schema.RecordTypeInfo rtMms = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_MMS, ObjectHelper.OBJECT_OPPTY);
        Schema.RecordTypeInfo rtHrs = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_401K, ObjectHelper.OBJECT_OPPTY);
        
        Opportunity opp1 = new Opportunity(Name='Test OppType1', AccountId=acct.Id, RecordTypeId=rtCore.getRecordTypeId(), CloseDate=Date.today().addDays(14), StageName='Pending');
        Opportunity opp2 = new Opportunity(Name='Test OppType2', AccountId=acct.Id, RecordTypeId=rtMms.getRecordTypeId(), CloseDate=Date.today().addDays(14), StageName='Pending');
        Opportunity opp3 = new Opportunity(Name='Test OppType3', AccountId=acct.Id, RecordTypeId=rtHrs.getRecordTypeId(), CloseDate=Date.today().addDays(14), StageName='Pending');
        Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3};
            insert opps;
        
        RecordType__c rtSettingCore = RecordTypeHelper.getRtSetting(OpportunityCreateCase.RT_OPPTY_CORE);
        RecordType__c rtSettingMMS = RecordTypeHelper.getRtSetting(OpportunityCreateCase.RT_OPPTY_MMS);
        RecordType__c rtSettingHRS = RecordTypeHelper.getRtSetting(OpportunityCreateCase.RT_OPPTY_401K);
        
        opp1 = [Select Id, Name, OpportunityType__c from Opportunity where Id = :opp1.Id];
        //System.assertEquals(OpptyMethods.OPP_TYPE_PAY, opp1.OpportunityType__c);
        System.assertEquals(rtSettingCore.OpportunityType__c, opp1.OpportunityType__c);
        opp2 = [Select Id, Name, OpportunityType__c from Opportunity where Id = :opp2.Id];
        //System.assertEquals(OpptyMethods.OPP_TYPE_PAY, opp2.OpportunityType__c);
        System.assertEquals(rtSettingMMS.OpportunityType__c, opp2.OpportunityType__c);
        opp3 = [Select Id, Name, OpportunityType__c from Opportunity where Id = :opp3.Id];
        //System.assertEquals(OpptyMethods.OPP_TYPE_HRS, opp3.OpportunityType__c);
        System.assertEquals(rtSettingHRS.OpportunityType__c, opp3.OpportunityType__c);
        
        Opportunity[] oppsToCheck = OpptyMethods.getOpportunities(acct.Id, 12, 10);
        System.assertEquals(opps.size(), oppsToCheck.size());
    } // testCheckOpportunityTypes
    
    static testMethod void testCheckOpportunityType2() {
        User runningUser = UserHelper.getRunningUser();
        //instead of this create recordtype__ setting 
        Account acct = new Account(Name='Test Acct', PEO_Potential_Indicator__c ='A');
        insert acct;    
        
        Schema.RecordTypeInfo rtCore = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, ObjectHelper.OBJECT_OPPTY);
        
        Opportunity opp = new Opportunity (Name='test1', AccountId=acct.Id, RecordTypeId=rtCore.getRecordTypeId(), CloseDate=Date.today().addDays(14), StageName='Pending' ); 
        insert opp; 
        system.debug('JC running user ' + runningUser); 
        
        OpptyMethods.checkOpportunityType(opp, null, runningUser, acct);
        
        RecordType__c rt = new RecordType__c(Name= 'PEO Opportunity Record Type', ObjectName__c='Opportunity', Sales_Org__c='PAS',RecordTypeName__c= 'PEO Opportunity Record Type', OpportunityType__c='PAS');
        insert rt;      
        Schema.RecordTypeInfo rtPEO = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_PEO, ObjectHelper.OBJECT_OPPTY);
        
        Opportunity opp1 = new Opportunity (Name='test1', AccountId=acct.Id, RecordTypeId=rtPEO.getRecordTypeId(), CloseDate=Date.today().addDays(14), StageName='Pending' ); 
        insert opp1; 
        
        OpptyMethods.checkOpportunityType(opp1, null, runningUser, acct);
        
        system.debug('JC opp.opptype '+ opp.OpportunityType__c); 
        opp1 = [Select Id, Name, OpportunityType__c from Opportunity where Id = :opp1.Id];
        
        System.assertEquals(opp1.OpportunityType__c, UserHelper.SO_PEO);   
    } // testCheckOpportunityType2*/
    
    static testMethod void checkForAudit() {
        // create the account and contact, set up the life of lead settings.
        ProspectOwnershipTest.setupAcctCtct();
        
        User[] outboundNSRs = ProspectOwnershipMethodsTest.getOutboundNSRs(2);
        Prospect_Ownership__c po1 = new Prospect_Ownership__c(Prospect_Client__c=ProspectOwnershipTest.acct.Id
                                                              ,Decision_Maker__c=ProspectOwnershipTest.ctct.Id
                                                              ,NSR_Name__c=outboundNSRs[0].Id
                                                              ,StartDate__c=Date.today().addDays(-30)
                                                              ,CommissionStart__c=Date.today().addDays(-30)
                                                              ,CommissionEnd__c=Date.today().addDays(90)
                                                              ,NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                                                              ,NSS_Team__c=UserHelper.SO_CORE
                                                             );
        insert po1;
        po1 = ProspectOwnershipMethods.getById(po1.Id);
        
        // create an opportunity
        Schema.RecordTypeInfo rtCore = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, ObjectHelper.OBJECT_OPPTY);
        Opportunity opp1 = new Opportunity(Name='Test OppType1', AccountId=ProspectOwnershipTest.acct.Id, RecordTypeId=rtCore.getRecordTypeId(), CloseDate=Date.today().addDays(14), StageName='Pending');
        insert opp1;
        // we should get the sales team member inserted here.
        
        System.assertEquals(1,[select count() from OpportunityTeamMember where OpportunityId=:opp1.Id and UserId=:outboundNSRs[0].Id and TeamMemberRole=:OpptyMethods.ROLE_NSR and Prospect_Ownership__c=:po1.Id]);
        NSSAudit__c audit1 = new NSSAudit__c(Account__c=ProspectOwnershipTest.acct.Id, NSR_Name__c=outboundNSRs[1].Id);
        insert audit1;
        
        // change stage name to sold - started - should trigger an audit record being created.
        opp1.StageName = Label.OppStage_Sold_Started;
        update opp1;
        
        System.assertEquals(1,[select count() from NSSAudit__c where NSR_Name__c=:outboundNSRs[0].Id and Opportunity__c=:opp1.Id and Prospect_Ownership__c=:po1.Id]);
        
        OpportunityTeamMember[] otms = [Select Id, OpportunityId, Prospect_Ownership__c, TeamMemberRole, UserId from OpportunityTeamMember where OpportunityId=:opp1.Id];
        System.debug('checkForAudit otms='+otms);
        
        // update the team member - remove the Prospect_Ownership__c link - make sure the process brings it back.
        OpportunityTeamMember otm1 = [Select Id, OpportunityId, Prospect_Ownership__c from OpportunityTeamMember where OpportunityId=:opp1.Id and UserId=:outboundNSRs[0].Id];
        otm1.Prospect_Ownership__c = null;
        update otm1;
        
        Schema.RecordTypeInfo rtMms = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_MMS, ObjectHelper.OBJECT_OPPTY);
        Schema.RecordTypeInfo rtHrs = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_401K, ObjectHelper.OBJECT_OPPTY);
        Opportunity opp2 = new Opportunity(Name='Test OppType2', AccountId=ProspectOwnershipTest.acct.Id, RecordTypeId=rtMms.getRecordTypeId(), CloseDate=Date.today().addDays(14), StageName='Pending');
        Opportunity opp3 = new Opportunity(Name='Test OppType3', AccountId=ProspectOwnershipTest.acct.Id, RecordTypeId=rtHrs.getRecordTypeId(), CloseDate=Date.today().addDays(14), StageName='Pending');
        Opportunity opp4 = new Opportunity(Name='Test OppType4', AccountId=ProspectOwnershipTest.acct.Id, RecordTypeId=rtCore.getRecordTypeId(), CloseDate=Date.today().addDays(14), StageName='Pending');
        Opportunity[] opps = new Opportunity[]{opp2,opp3,opp4};
            insert opps;
        
        // delete team member roles - let the process recreate them.
        delete [Select Id from OpportunityTeamMember where TeamMemberRole=:OpptyMethods.ROLE_NSR and (OpportunityId=:opp2.Id or OpportunityId=:opp3.Id or OpportunityId=:opp4.Id)];
        
        OpptyMethods.checkCommissionableOpps(new Prospect_Ownership__c[]{po1});
        
        System.assertEquals(1,[select count() from OpportunityTeamMember where OpportunityId=:opp1.Id and UserId=:outboundNSRs[0].Id and TeamMemberRole=:OpptyMethods.ROLE_NSR and Prospect_Ownership__c=:po1.Id]);
        System.assertEquals(1,[select count() from OpportunityTeamMember where OpportunityId=:opp2.Id and UserId=:outboundNSRs[0].Id and TeamMemberRole=:OpptyMethods.ROLE_NSR and Prospect_Ownership__c=:po1.Id]);
        System.assertEquals(1,[select count() from OpportunityTeamMember where OpportunityId=:opp3.Id and UserId=:outboundNSRs[0].Id and TeamMemberRole=:OpptyMethods.ROLE_NSR and Prospect_Ownership__c=:po1.Id]);
        System.assertEquals(1,[select count() from OpportunityTeamMember where OpportunityId=:opp4.Id and UserId=:outboundNSRs[0].Id and TeamMemberRole=:OpptyMethods.ROLE_NSR and Prospect_Ownership__c=:po1.Id]);
    } // checkForAudit
    
    private static Account getAccount(Id acctId) {
        Account acct = [Select Id, Name
                        ,HRSOppCreatedDate__c
                        ,HRSOppDateNotSold__c
                        ,HRSOppNSSSource__c
                        ,HRSOppStatus__c
                        ,LatestHRSOpp__c
                        ,LatestPayrollOpp__c
                        ,PAYOppCreatedDate__c
                        ,PAYOppDateNotSold__c
                        ,PAYOppNSSSource__c
                        ,PAYOppStatus__c
                        From Account Where Id=:acctId];
        return acct;
    } // getAccount
    
    static testMethod void testFormatClientNumbr() {
        System.assertEquals('',OpptyMethods.formatClientNumber2(''));
        System.assertEquals('00001234',OpptyMethods.formatClientNumber2('1234'));
        System.assertEquals('00231234',OpptyMethods.formatClientNumber2('23-1234'));
        System.assertEquals('12345678',OpptyMethods.formatClientNumber2('23-12345678'));
    } // testFormatClientNumbr
    
    static testMethod void testProductWon() {
        String[] prodNames = new String[]{'TestProd1','TestProd2'};     
            // setup products
        PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames, 'TestOrg', null);
        PricebookEntry entry1 = entries[0];
        PricebookEntry entry2 = entries[1];
        
        Product2 prod1 = new Product2(Id=entry1.Product2.Id, CreateAssetWhenSold__c=true);
        Product2 prod2 = new Product2(Id=entry2.Product2.Id, CreateAssetWhenSold__c=true);
        Product2[] prods = new Product2[]{prod1,prod2};
            update prods;
        
        
        Account acct = new Account(Name='Acct1');
        insert acct;
        
        OpptyMethods.checkWonOppRTSet();
        // get one of the record type names that already exist
        // if the label is empty - default it to this.
        if (OpptyMethods.wonOppRtIdSet.isEmpty()) {
            Schema.RecordTypeInfo rtInfo = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, ObjectHelper.OBJECT_OPPTY);
            OpptyMethods.wonOppRtIdSet.add(rtInfo.getRecordTypeId());
        }
        String[] oppRtIds = new String[]{};
            oppRtIds.addAll(OpptyMethods.wonOppRtIdSet);
        String oppRtId = oppRtIds[0];
                
        Opportunity opp = new Opportunity(Name='Opp 1',AccountId=acct.Id, CloseDate=Date.today(), StageName='Pending', RecordTypeId=oppRtId);
        insert opp;
        
        Asset asst1 = new Asset(AccountId=acct.Id, Name='Test 1',Product2Id=prod1.Id, Opportunity__c=opp.Id);
        insert asst1;
        
        System.assertEquals(1,[select count() from Asset where AccountId=:acct.Id]);
        
        OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId=opp.Id, PricebookEntryId=entry1.Id,Quantity=1,TotalPrice=1);
        OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId=opp.Id, PricebookEntryId=entry2.Id,Quantity=1,TotalPrice=1);
        OpportunityLineItem[] olis = new OpportunityLineItem[]{oli1,oli2};
            insert olis;
        
        opp.StageName = Label.OppStage_Sold_Started;
        update opp;
        
        opp = [Select Id, Name, IsWon, IsClosed from Opportunity where Id=:opp.Id];      
        System.assertEquals(true,opp.IsWon);
        System.assertEquals(true,opp.IsClosed);
        
        // should be two assets now.
        System.assertEquals(2,[select count() from Asset where AccountId=:acct.Id]);
        // second asset should be linked to the second product
        System.assertEquals(1,[select count() from Asset where AccountId=:acct.Id and Product2Id=:prod2.Id]);
        
    } // testProductWon
    
    static testMethod void testReferralLinking() {
        Account acct1 = new Account(Name='Acct 1');
        Account acct2 = new Account(Name='Acct 2');
        Account acct3 = new Account(Name='Acct 3');
        Account acct4 = new Account(Name='Acct 4');
        Account[] accts = new Account[]{acct1,acct2,acct3,acct4};
            insert accts;
        
        Lead ld1 = new Lead(Company='Lead1', LastName='LeadLast1');
        Lead ld2 = new Lead(Company='Lead2', LastName='LeadLast2');
        Lead[] lds = new Lead[]{ld1,ld2};
            insert lds;
        
        Referral__c ref1 = new Referral__c(Name='Ref 1', Account__c=acct1.Id, Referral_Id__c='Test1');
        Referral__c ref2 = new Referral__c(Name='Ref 2', Account__c=acct2.Id, Referral_Id__c='Test2');
        Referral__c ref3 = new Referral__c(Name='Ref 3', Account__c=acct3.Id, Referral_Id__c='Test3');
        Referral__c ref4 = new Referral__c(Name='Ref 4', SourceLead__c=ld1.Id, Referral_Id__c='Test4');
        Referral__c[] refs = new Referral__c[]{ref1,ref2,ref3,ref4};
            insert refs;
        
        Opportunity opp1 = new Opportunity(Name='Opp1', AccountId=acct1.Id, CloseDate=Date.today(), StageName='Pending', Bank_Lead_ID__c=ref1.Referral_Id__c);
        // this one shouldn't link up because of wrong account
        Opportunity opp2 = new Opportunity(Name='Opp2', AccountId=acct2.Id, CloseDate=Date.today(), StageName='Pending', Bank_Lead_ID__c=null);
        Opportunity opp3 = new Opportunity(Name='Opp3', AccountId=acct3.Id, CloseDate=Date.today(), StageName='Pending', Bank_Lead_ID__c=null);
        Opportunity opp4 = new Opportunity(Name='Opp4', AccountId=acct4.Id, CloseDate=Date.today(), StageName='Pending', Bank_Lead_ID__c=ref4.Referral_Id__c);
        Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3,opp4};
            insert opps;
        
        opp1 = [Select Id, Name, ReferralLookup__c, Bank_Lead_ID__c from Opportunity where Id=:opp1.Id];
        System.assertEquals(ref1.Id, opp1.ReferralLookup__c);
        ref1 = [Select Id, Name, Referral_Id__c, Selling_Opportunity__c from Referral__c where Id=:ref1.Id];
        System.assertEquals(opp1.Id, ref1.Selling_Opportunity__c);
        
        opp2 = [Select Id, Name, ReferralLookup__c, Bank_Lead_ID__c from Opportunity where Id=:opp2.Id];
        System.assertEquals(null, opp2.ReferralLookup__c);
        ref2 = [Select Id, Name, Referral_Id__c, Selling_Opportunity__c from Referral__c where Id=:ref2.Id];
        System.assertEquals(null, ref2.Selling_Opportunity__c);
        
        opp3 = [Select Id, Name, ReferralLookup__c, Bank_Lead_ID__c from Opportunity where Id=:opp3.Id];
        System.assertEquals(null, opp3.ReferralLookup__c);
        ref3 = [Select Id, Name, Referral_Id__c, Selling_Opportunity__c from Referral__c where Id=:ref3.Id];
        System.assertEquals(null, ref3.Selling_Opportunity__c);
        
        opp2.Bank_Lead_ID__c = ref2.Referral_Id__c;
        opp3.Bank_Lead_ID__c = ref3.Referral_Id__c;
        opps = new Opportunity[]{opp1,opp2,opp3};
            update opps;
        
        opp1 = [Select Id, Name, ReferralLookup__c, Bank_Lead_ID__c from Opportunity where Id=:opp1.Id];
        System.assertEquals(ref1.Id, opp1.ReferralLookup__c);
        ref1 = [Select Id, Name, Referral_Id__c, Selling_Opportunity__c from Referral__c where Id=:ref1.Id];
        System.assertEquals(opp1.Id, ref1.Selling_Opportunity__c);
        
        opp2 = [Select Id, Name, ReferralLookup__c, Bank_Lead_ID__c from Opportunity where Id=:opp2.Id];
        System.assertEquals(ref2.Id, opp2.ReferralLookup__c);
        ref2 = [Select Id, Name, Referral_Id__c, Selling_Opportunity__c from Referral__c where Id=:ref2.Id];
        System.assertEquals(opp2.Id, ref2.Selling_Opportunity__c);
        
        opp3 = [Select Id, Name, ReferralLookup__c, Bank_Lead_ID__c from Opportunity where Id=:opp3.Id];
        System.assertEquals(ref3.Id, opp3.ReferralLookup__c);
        ref3 = [Select Id, Name, Referral_Id__c, Selling_Opportunity__c from Referral__c where Id=:ref3.Id];
        System.assertEquals(opp3.Id, ref3.Selling_Opportunity__c);
        
        ref4 = [Select Id, Name, Referral_Id__c, Account__c, SourceLead__c, Selling_Opportunity__c from Referral__c where Id=:ref4.Id];
        System.assertEquals(opp4.Id, ref4.Selling_Opportunity__c);
        System.assertEquals(acct4.Id, ref4.Account__c);
        System.assertEquals(null, ref4.SourceLead__c);
        
        
    } // testReferralLinking
    
    public static User getUser(String profName) {
        User usr = null;
        try {
            usr = [SELECT Id,Sales_Org__c FROM User WHERE Profile.Name = :profName AND IsActive = true LIMIT 1];
        } catch (Exception e) {
            System.debug('getUser unable to find a user with the profile '+profName);
        }
        return usr;
    }
    
    static testmethod void testDefaultRTVirtual(){
        User virtualUser = getUser(Utilities.PROF_CORE_VIRTUAL_SALES);
        User coreUser = getUser(Utilities.PROF_CORE_SALES_SB);
        
        SalesOrg__c salesOrgSetting = SalesOrg__c.getInstance(UserHelper.SO_CORE);
        
        Map<String,Schema.RecordTypeInfo> opptyRTMap = RecordTypeHelper.getRecordTypeByNameMap('Opportunity');
        Id virtualRTId = OpptyMethods.getRtIdFromMap('Core Virtual Sales',opptyRTMap);
        Id coreRTId = OpptyMethods.getRtIdFromMap(salesOrgSetting.OpptyRecordTypeName__c,opptyRTMap);
        
        Account acct = new Account(Name='Acct');
        insert acct;
        
        Test.startTest();
        Opportunity vOppty = new Opportunity(CloseDate=Date.today(), StageName='Pending', Name = 'Oppty Virtual', AccountId = acct.id, NSS_Source__c = 'Inbound', OwnerId = virtualUser.Id, RecordTypeId=coreRTId);
        
        Opportunity[] opptys = new Opportunity[]{vOppty};
            insert opptys;
        
        Map<Id,Opportunity> opptyMap = new Map<Id,Opportunity>([SELECT Id,OwnerId,Owner.Profile.Name,RecordTypeId FROM Opportunity WHERE Id in :opptys]);
        Opportunity virtualOppty = opptyMap.get(vOppty.Id);
        
        system.assertEquals(virtualRTId,virtualOppty.RecordTypeId);
        
        virtualOppty.OwnerId = coreUser.Id;
        
        opptys = new Opportunity[]{virtualOppty};
            update opptys;
        
        Map<Id,Opportunity> updatedOpptyMap = new Map<Id,Opportunity>([SELECT Id,OwnerId,Owner.Profile.Name,RecordTypeId FROM Opportunity WHERE Id in :opptys]);
        Opportunity coreOppty = updatedOpptyMap.get(virtualOppty.Id);
        
        system.assertEquals(coreRTId,coreOppty.RecordTypeId);
        
        Test.stopTest();
    } // testDefaultRT
    
    static testmethod void testSetForecastProbabilityFromOppStage(){
        Account acct = new Account(Name='Acct');
        insert acct;
        
        Id coreRTId = RecordTypeHelper.getRecordType('Core Opportunity Record Type','Opportunity').getRecordTypeId();
        Opportunity oppty = new Opportunity(CloseDate=Date.today(), StageName='Pending', Name = 'Oppty 1', AccountId = acct.id, NSS_Source__c = 'Inbound', RecordTypeId=coreRTId);
        insert oppty;
        
        OpportunityStage os = [SELECT MasterLabel,DefaultProbability,ForecastCategoryName FROM OpportunityStage WHERE IsActive=true AND MasterLabel != :oppty.StageName LIMIT 1];
        Test.startTest();
        oppty.StageName = os.MasterLabel;
        update oppty;
        Opportunity uOppty = [SELECT Id,StageName,Probability,ForecastCategoryName From Opportunity WHERE Id = :oppty.Id LIMIT 1];
        system.assertEquals(os.DefaultProbability,uOppty.Probability); 
        system.assertEquals(os.ForecastCategoryName,uOppty.ForecastCategoryName); 
        
        Test.stopTest();
    }
    
    static testmethod void testReferralRunEffectiveSync(){
        
        Account acct = new Account(Name='Acct');
        insert acct;
        
        Id coreRTId = RecordTypeHelper.getRecordType('Core Opportunity Record Type','Opportunity').getRecordTypeId();
        Opportunity oppty1 = new Opportunity(CloseDate=Date.today(),StageName=Label.OppStage_Qualified, Name = 'Oppty 1', AccountId = acct.id, NSS_Source__c = 'Inbound', RecordTypeId=coreRTId);
        Opportunity oppty2 = new Opportunity(CloseDate=Date.today(),StageName=Label.OppStage_Qualified, Name = 'Oppty 2', AccountId = acct.id, NSS_Source__c = 'Inbound', RecordTypeId=coreRTId);
        Opportunity[] opptys = new Opportunity[]{oppty1,oppty2};
            insert opptys;
        
        Referral__c ref = new Referral__c(Name='test',Referring_Opportunity__c=oppty1.Id,Selling_Opportunity__c=oppty2.Id);
        insert ref;
        
        oppty1.ReferralLookup__c = ref.Id;
        oppty2.ReferralLookup__c = ref.Id;
        update opptys;
        
        Test.startTest();
        oppty2.CloseDate = date.today().addDays(10);
        update oppty2;
        Opportunity uOppty1 = [SELECT CloseDate FROM Opportunity WHERE Id = :oppty1.Id];
        system.assertEquals(oppty2.CloseDate,uOppty1.CloseDate);
        
        oppty2.CloseDate = date.today().addDays(5);
        update oppty2;
        uOppty1 = [SELECT CloseDate FROM Opportunity WHERE Id = :oppty1.Id];
        system.assert(oppty2.CloseDate!=uOppty1.CloseDate);
        Test.stopTest();
    }
    
    static testmethod void testPayrollPlatformChange(){
        Account acct = new Account(Name='Acct');
        insert acct;
        
        Map<String,Schema.RecordTypeInfo> opptyRTMap = RecordTypeHelper.getRecordTypeByNameMap('Opportunity');
        Id peoRTId = OpptyMethods.getRtIdFromMap('PEO Opportunity Record Type',opptyRTMap);
        Id peoFSSRTId = OpptyMethods.getRtIdFromMap('PEO Opportunity FSS Record Type',opptyRTMap);
        Id peoRefRTId = OpptyMethods.getRtIdFromMap('PEO Referral Revenue Opportunity',opptyRTMap); 
        
        Id asoRTId = OpptyMethods.getRtIdFromMap('ASO Opportunity Record Type',opptyRTMap);
        Id asoFSSRTId = OpptyMethods.getRtIdFromMap('ASO Opportunity FSS Record Type',opptyRTMap);
        Id asoRefRTId = OpptyMethods.getRtIdFromMap('ASO Referral Revenue Opportunity',opptyRTMap);
        
        // Id prismRTId = OpptyMethods.getRtIdFromMap('Prism PEO Opportunity Record Type',opptyRTMap);
        // Id prismFSSRTId = OpptyMethods.getRtIdFromMap('Prism PEO Opportunity FSS Record Type',opptyRTMap); 
        // Id prismRefRTId = OpptyMethods.getRtIdFromMap('Prism PEO Referral Revenue Opportunity',opptyRTMap);
        
        ID payRTId = OpptyMethods.getRtIdFromMap('Core Opportunity Record Type',opptyRTMap);
        Id payDSARTId = OpptyMethods.getRtIdFromMap('Core Opportunity DSA Record Type',opptyRTMap);
        Id payRefRTId = OpptyMethods.getRtIdFromMap('Core Referral Revenue Opportunity Record Type - Rep',opptyRTMap);
        
        ID mmsRTId = OpptyMethods.getRtIdFromMap('MMS Opportunity Record Type',opptyRTMap);
        Id mmsDSARTId = OpptyMethods.getRtIdFromMap('MMS Opportunity (DSA) Record Type',opptyRTMap);
        Id mmsRefRTId = OpptyMethods.getRtIdFromMap('MMS Referral Revenue Opportunity - Rep',opptyRTMap);
        
        Opportunity oppty1 = new Opportunity(CloseDate=Date.today(),StageName=Label.OppStage_Qualified, Name = 'Oppty 1', AccountId = acct.id, Payroll_Platform__c = 'PEO', RecordTypeId=peoRTId);
        //Opportunity oppty2 = new Opportunity(CloseDate=Date.today(),StageName=Label.OppStage_Qualified, Name = 'Oppty 2', AccountId = acct.id, Payroll_Platform__c = 'PEO', RecordTypeId=peoFSSRTId);
        //Opportunity oppty3 = new Opportunity(CloseDate=Date.today(),StageName=Label.OppStage_Qualified, Name = 'Oppty 3', AccountId = acct.id, Payroll_Platform__c = 'PEO', RecordTypeId=peoRefRTId);
        Opportunity oppty4 = new Opportunity(CloseDate=Date.today(),StageName=Label.OppStage_Qualified, Name = 'Oppty 4', AccountId = acct.id, Payroll_Platform__c = 'ASO', RecordTypeId=asoRTId);
        //Opportunity oppty5 = new Opportunity(CloseDate=Date.today(),StageName=Label.OppStage_Qualified, Name = 'Oppty 5', AccountId = acct.id, Payroll_Platform__c = 'ASO', RecordTypeId=asoFSSRTId);
        //Opportunity oppty6 = new Opportunity(CloseDate=Date.today(),StageName=Label.OppStage_Qualified, Name = 'Oppty 6', AccountId = acct.id, Payroll_Platform__c = 'ASO', RecordTypeId=asoRefRTId);
        //Opportunity oppty7 = new Opportunity(CloseDate=Date.today(),StageName=Label.OppStage_Qualified, Name = 'Oppty 7', AccountId = acct.id, Payroll_Platform__c = 'PRISM PEO', RecordTypeId=prismRTId);
        //Opportunity oppty8 = new Opportunity(CloseDate=Date.today(),StageName=Label.OppStage_Qualified, Name = 'Oppty 8', AccountId = acct.id, Payroll_Platform__c = 'PRISM PEO', RecordTypeId=prismFSSRTId);
        //Opportunity oppty9 = new Opportunity(CloseDate=Date.today(),StageName=Label.OppStage_Qualified, Name = 'Oppty 9', AccountId = acct.id, Payroll_Platform__c = 'PRISM PEO', RecordTypeId=prismRefRTId);
        //Opportunity[] opptys = new Opportunity[]{oppty1,oppty2,oppty3,oppty4,oppty5,oppty6,oppty7,oppty8,oppty9};
        Opportunity[] opptys = new Opportunity[]{oppty1,oppty4};
            insert opptys;
        
        Id[] opptyIds = new Id[]{};
            for(Opportunity oppty:opptys){
                opptyIds.add(oppty.Id);
            }
        
        Test.startTest();
        oppty1.Payroll_Platform__c = 'Prism PEO';
        //oppty2.Payroll_Platform__c = 'ASO';
        //oppty3.Payroll_Platform__c = 'Prism PEO';
        oppty4.Payroll_Platform__c = 'Prism PEO';
        //oppty5.Payroll_Platform__c = 'Prism PEO';
        //oppty6.Payroll_Platform__c = 'Prism PEO';
        //oppty1.Payroll_Platform__c = 'PEO';
        //oppty2.Payroll_Platform__c = 'PEO';
        //oppty3.Payroll_Platform__c = 'PEO';
        update opptys;
        
        Opportunity[] updatedOpptys = [SELECT Id,RecordTypeId,Service_Location__c FROM Opportunity WHERE Id in:opptyIds ORDER BY Name];
        
        //system.assertEquals(prismRTId,updatedOpptys[0].RecordTypeId);
        //system.assertEquals(asoFSSRTId,updatedOpptys[1].RecordTypeId);
        //system.assertEquals(asoRefRTId,updatedOpptys[2].RecordTypeId);
        //system.assertEquals(prismRTId,updatedOpptys[1].RecordTypeId);
        //system.assertEquals(prismFSSRTId,updatedOpptys[4].RecordTypeId);
        //system.assertEquals(prismRefRTId,updatedOpptys[5].RecordTypeId);
        //system.assertEquals(peoRTId,updatedOpptys[0].RecordTypeId);
        //system.assertEquals(peoFSSRTId,updatedOpptys[1].RecordTypeId);
        //system.assertEquals(peoRefRTId,updatedOpptys[2].RecordTypeId);
        Test.stopTest();
    }
    
    static testMethod void testSwitchOppOwnerToInactiveUser() {
        Account acct = new Account(Name='Acct');
        insert acct;
        
        Id coreRTId = RecordTypeHelper.getRecordType('Core Opportunity Record Type','Opportunity').getRecordTypeId();  
        
        User activeUser = [SELECT Id FROM User WHERE IsActive=True AND Profile.name='System Administrator' LIMIT 1];
        User inactiveUser = [SELECT Id FROM User WHERE IsActive=False AND Profile.name='System Administrator' LIMIT 1];
        
        Opportunity oppty = new Opportunity(StageName=Label.OppStage_Qualified, CloseDate=Date.today(), Name = 'Oppty 1', RecordTypeId=coreRTId, OwnerId=activeUser.Id, Inactive_User_Id__c=null);
        insert oppty;
        
        test.startTest();
        oppty.Inactive_User_Id__c=inactiveUser.Id;
        update oppty;
        
        Test.stopTest();
    } //testSwitchOppOwnerToInactiveUser
    
    static testMethod void testSendNotSoldEmailToMyCorp() {
        User oppOwner = [SELECT Id FROM User WHERE Sales_Org__c = 'PAY' AND isActive = true LIMIT 1];
        Account acct = new Account(Name = 'Acct', OwnerId = oppOwner.Id);
        insert acct;
        Id coreRTId = RecordTypeHelper.getRecordType('Core Opportunity Record Type','Opportunity').getRecordTypeId();
        Opportunity oppty1 = new Opportunity(CloseDate=Date.today(), StageName=Label.OppStage_Qualified, Name = 'Oppty1', AccountId = acct.id, RecordTypeId=coreRTId, OwnerId = oppOwner.Id);
        insert oppty1;
        
        Referral__c ref1 = new Referral__c(Name='Ref 1', Account__c=acct.Id, Referral_Id__c='Test1', ReferralPartnerName__c = 'MyCorp (Solo Bundle)');
        Contact c = new Contact(AccountId=acct.id, LastName = 'Contact', FirstName = 'MyCorporation');
        insert c;
        insert ref1;
        
        Id pricebookId = Test.getStandardPricebookId();
        Product2 prod = new Product2(
            Name = 'Paychex Solo',
            ProductCode = 'PSolo',
            isActive = true
        );
        insert prod;
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry;
        
        Integer Quantity = 1;
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = oppty1.Id,
            Quantity = Quantity,
            PricebookEntryId = pbEntry.Id,
            TotalPrice = Quantity * pbEntry.UnitPrice
        );
        insert oli;
        
        test.startTest();
        oppty1.StageName = Label.OppStage_Lost;
        update oppty1;
        Map<Id,Opportunity> opportunitiesNotSoldSoloMyCorp = new Map<Id,Opportunity>();
        opportunitiesNotSoldSoloMyCorp.put(oppty1.Id,oppty1);
        OpptyMethods.sendNotSoldEmailToMyCorp(opportunitiesNotSoldSoloMyCorp);
        test.StopTest();
        System.assertEquals(OpptyMethods.MYCORP_EMAIL_SENT, true);
        
    } //testSendNotSoldEmailToMyCorp
    
    static testMethod void testAccountUpdateHoldout(){
        User oppOwner = [SELECT Id FROM User WHERE Sales_Org__c = 'PAY' AND Job_Name__c=:UserHelper.JOB_REP AND isActive = true LIMIT 1]; 
        oppOwner.SMB_Certified__c = date.today();
        update oppOwner;
    
    	User oppHRSOwner = [SELECT Id FROM User WHERE Sales_Org__c = 'HRS' AND Job_Name__c=:UserHelper.JOB_REP AND isActive = true LIMIT 1]; 
        
        HoldOut_ExpirationDates__c hoPAY = new HoldOut_ExpirationDates__c(Name='PAY',Sales_Org__c='PAY',Account_Hold_Out__c='Hold_Out__c',Account_Hold_Out_Date__c='Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=30,Account_Date_Field__c='First_Run_Date__c',OptySoldNumberOfDays__c=90,
                                                                          TaskNumberOfDays__c=90,UseForOwnershipChange__c=true,HoldOutReasonFld__c='Permanent_Hold_Out_Description__c'
                                                                          ,Account_Owner__c='OwnerId',Sold_Oppty_Hold_Out_Expiration_Duration__c = 90, SoldOppHoldOutReason__c='Payroll Sale');
        HoldOut_ExpirationDates__c hoMMS = new HoldOut_ExpirationDates__c(Name='MMS',Sales_Org__c='MMS',Account_Hold_Out__c='Hold_Out__c',Account_Hold_Out_Date__c='Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=120,Account_Date_Field__c='First_Run_Date__c',OptySoldNumberOfDays__c=120
                                                                          ,Account_Owner__c='OwnerId',Sold_Oppty_Hold_Out_Expiration_Duration__c = 365, SoldOppHoldOutReason__c='Payroll Sale');
    	HoldOut_ExpirationDates__c hoHRS = new HoldOut_ExpirationDates__c(Name='HRS',Sales_Org__c='HRS',Account_Hold_Out__c='Premier_PBS_Hold_Out__c',Account_Hold_Out_Date__c='Premier_PBS_Hold_Out_Expiration__c',                     InitialNumberofDays__c=120, Account_Owner__c='Premier_PBS_Account_Owner__c');                                  
        
        HoldOut_ExpirationDates__c[] hoList = new HoldOut_ExpirationDates__c[]{hoPAY,hoMMS,hoHRS};
        insert hoList;
        
        System.debug('hoList[0] ===================>>>>>> ' + hoList[0].Sold_Oppty_Hold_Out_Expiration_Duration__c);
        System.debug('hoList[1] ===================>>>>>> ' + hoList[1].Sold_Oppty_Hold_Out_Expiration_Duration__c);
        
        Account acct = new Account(Name='Acct',OwnerId = oppOwner.Id);
        insert acct;
        Account acctHRS = new Account(Name = 'Test HRS Hold Out', OwnerId = oppHRSOwner.Id);
        insert acctHRS;
    
        Referral_Partner__c rp1 = new Referral_Partner__c(Name=Label.VS_HRS_Virtual,Partner_Type__c=ReferralController.REF_NSS,Sort_Order__c=17,Ref_To_Type__c='User',CreateRefOpp__c=false, IsActive__c=true, Always_Check_Send_Email__c=false);
        insert rp1;   
        Referral__c ref1 = new Referral__c(Name='Ref1',Account__c=acctHRS.Id,Referral_Partner__c=rp1.Id);
        insert ref1;
        
        //Id MMSRTId = RecordTypeHelper.getRecordType('MMS Opportunity (DSA) Record Type','Opportunity').getRecordTypeId();
        Id MMSRTId = RecordTypeHelper.getRecordType('Core Opportunity Record Type','Opportunity').getRecordTypeId();
        Opportunity oppty1 = new Opportunity(CloseDate=Date.today(),StageName='Plan', Name = 'Oppty 1', AccountId = acct.id, RecordTypeId=MMSRTId, OwnerId = oppOwner.Id, Payroll_Units__c= 2, OpportunityType__c = 'Payroll');
        insert oppty1;
        Opportunity opptyHRS = new Opportunity(CloseDate=Date.today(),StageName='Qualified', Name = 'Oppty HRS', AccountId = acctHRS.id, RecordTypeId=MMSRTId, OwnerId = oppHRSOwner.Id, OpportunityType__c = 'Payroll',ReferralLookup__c=ref1.Id);
        insert opptyHRS;
        
        test.startTest();
        //System.runAs(oppOwner){
        oppty1.StageName = Label.OppStage_Sold_Started;
        update oppty1;
        //}
        test.stopTest();
        Account uAcct = [Select Id,Hold_Out__c,Hold_Out_Expiration__c FROM Account WHERE Id = :acct.Id];
        system.assertEquals(true,uAcct.Hold_Out__c);
        //system.assertEquals(date.today().addDays(90),uAcct.Hold_Out_Expiration__c);
    
        Account hrsAcct = [Select Id,Premier_PBS_Account_Owner__c,Premier_PBS_Hold_Out__c FROM Account WHERE Id = :acctHRS.Id];
        system.assertEquals(true,hrsAcct.Premier_PBS_Hold_Out__c);
        
    }
    
    static testMethod void testNssSource() {
        HoldOut_Dictionary__c hod1 = new HoldOut_Dictionary__c(Name='HoldOut1', NSSSource__c='Source1');
        HoldOut_Dictionary__c hod2 = new HoldOut_Dictionary__c(Name='HoldOut2', NSSSource__c=null);
        HoldOut_Dictionary__c[] hods = new HoldOut_Dictionary__c[]{hod1,hod2};
            insert hods;
        
        Account acct1 = new Account(Name='Account1', Hold_Out__c=true, Permanent_Hold_Out_Description__c='HoldOut1');
        Account acct2 = new Account(Name='Account2', Hold_Out__c=true, Permanent_Hold_Out_Description__c='HoldOut2');
        Account acct3 = new Account(Name='Account3', Hold_Out__c=true, Permanent_Hold_Out_Description__c='HoldOut3');
        Account[] accts = new Account[]{acct1,acct2,acct3};
            ZipCheckOwner.SKIP_TRIGGERS=true;
        insert accts;
        
        Opportunity opp1 = new Opportunity(AccountId=acct1.Id, Name='Opp1', CloseDate=Date.today().addDays(7), StageName='Pending', NSS_Source__c='Opp1');
        Opportunity opp2 = new Opportunity(AccountId=acct2.Id, Name='Opp2', CloseDate=Date.today().addDays(7), StageName='Pending', NSS_Source__c='Opp2');
        Opportunity opp3 = new Opportunity(AccountId=acct3.Id, Name='Opp3', CloseDate=Date.today().addDays(7), StageName='Pending', NSS_Source__c='Opp3');
        Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3};
            
            Test.startTest();
        insert opps;
        Test.stopTest();
        
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([Select Id, AccountId, NSS_Source__c from Opportunity]);
        opp1 = oppMap.get(opp1.Id);
        System.assertEquals('Source1',opp1.NSS_Source__c);
        opp2 = oppMap.get(opp2.Id);
        System.assertEquals('Opp2',opp2.NSS_Source__c);
        opp3 = oppMap.get(opp3.Id);
        System.assertEquals('Opp3',opp3.NSS_Source__c);
        
        
    } // testNssSource
    
    static testMethod void updateChecklistStepForNotSoldOpptytest() {
        Account acct1 = new Account(Name='test1');
        Account acct2 = new Account(Name='test2');
        Account[] accts = new Account[]{acct1,acct2};
            insert accts;
        
        Schema.RecordTypeInfo peoOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_PEO,'Opportunity');
        Opportunity opptyA = new Opportunity(Name='testOpptyA', RecordTypeId=peoOpptyRt.getRecordTypeId()
                                             ,AccountId=acct1.id
                                             ,StageName='Open'
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,CloseDate=Date.today().addDays(30));
        insert opptyA;
        PEO_Onboarding_Checklist__c chk = new PEO_Onboarding_Checklist__c(Opportunity__c=opptyA.Id, Prospect_Client__c=acct1.Id);
        insert chk;
        
        Test.startTest();
        //CommunityMethods.updateChecklistStepForLostOppty(new Set<Id>{opptyA.Id}, 'Test');
        OpptyMethods.sendChecklistUpdateForLostOppty(new Set<Id>{opptyA.Id});
        test.stopTest();
        PEO_Onboarding_Checklist__c checklists = [SELECT Id, Current_Step__c, Abandoned_Status_Date__c FROM PEO_Onboarding_Checklist__c WHERE Opportunity__c=:opptyA.Id LIMIT 1];
        System.assertEquals('Lost',checklists.Current_Step__c);
        //system.assertEquals(expected, actual)
        
    }

    static testMethod void updateChecklistOwnerWithOptyOwnertest() {
        Account acct1 = new Account(Name='test1');
        Account acct2 = new Account(Name='test2');
        Account[] accts = new Account[]{acct1,acct2};
            insert accts;
        //User[] userList = [SELECT ID from User WHERE isActive = true AND Profile.Name = 'System Administrator' LIMIT 2];
        
        Schema.RecordTypeInfo peoOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_PEO,'Opportunity');
        Opportunity opptyA = new Opportunity(Name='testOpptyA', RecordTypeId=peoOpptyRt.getRecordTypeId()
                                             ,AccountId=acct1.id
                                             ,StageName='Lost'
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,CloseDate=Date.today().addDays(30));
        insert opptyA;
        system.debug('opptyA:'+opptyA);
        PEO_Onboarding_Checklist__c chk = new PEO_Onboarding_Checklist__c(Opportunity__c=opptyA.Id, Prospect_Client__c=acct1.Id);
        insert chk;
        
        Test.startTest();
        //CommunityMethods.updateChecklistOwnerWithOptyOwner(new Set<Id>{opptyA.Id}, 'Test');
        OpptyMethods.sendChecklistUpdateForOwnerChange(new Set<Id>{opptyA.Id});
        test.stopTest();
        PEO_Onboarding_Checklist__c checklists = [SELECT Id, Current_Step__c, Abandoned_Status_Date__c, Sales_Rep__c FROM PEO_Onboarding_Checklist__c WHERE Opportunity__c=:opptyA.Id LIMIT 1];
        Opportunity optys = [SELECT Id, OwnerId FROM Opportunity WHERE AccountId=:acct1.id LIMIT 1];
        System.assertEquals(checklists.Sales_Rep__c, optys.OwnerId);
        
    }
    
    static testmethod void testEndDate(){
      
      Account acct = new Account(Name='Acct');
      insert acct;
         
      Id coreRTId = RecordTypeHelper.getRecordType('Core Opportunity Record Type','Opportunity').getRecordTypeId();
      Opportunity oppty = new Opportunity(CloseDate=Date.today(),StageName=Label.OppStage_Qualified, Name = 'Oppty 1', AccountId = acct.id, RecordTypeId=coreRTId);
      insert oppty;
      
      Referral__c ref = new Referral__c(Name='test',Selling_Opportunity__c=oppty.Id);
      insert ref;
      
      Test.startTest();
      oppty.StageName = Label.OppStage_No_Decision;
      update oppty;
        
      Referral__c refChk = [SELECT Id, Selling_Opportunity__c, Referral_End_Date__c FROM Referral__c WHERE Id=:ref.Id limit 1];
      System.assertEquals(true, refChk.Referral_End_Date__c!=null);
      Test.stopTest();
    } 

        /**BAU Changes**/
        static testmethod void testsendChatterMessageToSDRusers(){

            UserRole userroleManager=new UserRole(Name='Oasis Manager'); 
            insert userroleManager; 
            Profile profManager = [select id from profile where name='HRS PEO Centric Administration'];
            User userManager = new User(Alias = 'Edward1',TimeZoneSidKey='America/Los_Angeles',EmailEncodingKey='UTF-8',LanguageLocaleKey='en_US' ,LocaleSidKey='en_US');
            userManager.firstName ='Edward1';
            userManager.lastName = 'Owen1';
            userManager.profileId = profManager.id;
            userManager.username =' eowen1@paychex.com.fullsandbx';
            userManager.email ='eowen1@oasispeo.com.invalid';
            userManager.UserRoleId =userroleManager.Id;
            //userManager.Sales_Org__c='PEO';
            userManager.Sales_Org__c='NSS';
            insert userManager;
    
            UserRole userrole=new UserRole(Name='Oasis SDR'); 
            insert userrole; 
            Profile prof = [select id from profile where name='Oasis Outbound Rep'];
            User user1 = new User(Alias = 'kruff1',TimeZoneSidKey='America/Los_Angeles',EmailEncodingKey='UTF-8',LanguageLocaleKey='en_US' ,LocaleSidKey='en_US');
            user1.firstName ='Kent1';
            user1.lastName = 'Ruffo1';
            user1.profileId = prof.id;
            user1.username ='kruffo1@paychex.com.fullsandbx';
            user1.email ='kruffo1@oasispeo.com.invalid';
            user1.UserRoleId =userrole.Id;
            user1.managerId=userManager.Id;
            //user1.Sales_Org__c='PEO';
            user1.Sales_Org__c='NSS';
            insert user1;
    
            System.runAs(user1){
            Account acct = new Account(Name='Test Acct');
            insert acct;
    
    
            Set<Id> setOppId=new Set<Id>();
            Opportunity opp= new Opportunity(Name='Test Opp1', AccountId=acct.Id, CloseDate=Date.today().addDays(14), StageName='Qualified');
            insert opp;
            setOppId.add(opp.id);
    
            List<OpportunityTeamMember> otms=new List<OpportunityTeamMember>();
            OpportunityTeamMember otm= new OpportunityTeamMember(OpportunityId=opp.Id, UserId=user1.Id, TeamMemberRole='Oasis SDR');
            otms.add(otm);
            insert otm;
            
            
    
            test.starttest();
            OpptyMethods.sendChatterMessageToSDRusers(setOppId);
            OpptyMethods.InsertOTMs(otms);
            OpportunityTeamMemberHandler.NotifySRWhenRemovedFromOpp(otms);
            OpportunityTeamMemberHandler.insertProspectClientTeamMember(otms);
            test.stopTest();
    
            }
            
        }
        /**BAU Changes**/
     static testMethod void testsetDSAonOpp(){
        Account acct1 = new Account(Name='Test Account1', ShippingPostalCode='12345');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert new Account[]{acct1};
          Schema.RecordTypeInfo rtInbound = CallCenterHelper.getInboundRt();
      
      DS_Denali__DialSource_Sessions_V3__c dsSession = new DS_Denali__DialSource_Sessions_V3__c(Name='Test Session'
                                                                              ,DS_Denali__Session_Date__c=Datetime.now());
      insert dsSession;
      
      DS_Denali__DialSource_Action__c action1 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtInbound.getRecordTypeId()
                                                       ,DS_Denali__Owner__c=UserInfo.getUserId()
                                                       ,DS_Denali__Account__c=acct1.Id
                                                       ,DS_Denali__Call_Campaign__c='Call Campaign2'
                                                       ,DS_Denali__Phone__c='5551234570'
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id
                                                       ,DS_Denali__Inbound_DNIS__c='InboundCall'
                                                       ,DS_Denali__Inbound_DNIS_Name__c='DNIS Name2');
      insert new DS_Denali__DialSource_Action__c[]{action1};
      Test.setCreatedDate(action1.Id, Datetime.now().addHours(10));
         Test.startTest();
        Opportunity opp= new Opportunity(Name='Test DSA Opp', AccountId=acct1.Id, CloseDate=Date.today().addDays(14), StageName='Qualified');
      insert opp; 
        Opportunity opDSA = [select DialSource_Action__c,DialSource_Action__r.Id from Opportunity where Name='Test DSA Opp' limit 1];
        //System.assertEquals(opDSA.DialSource_Action__r.Id, action1.Id);
         Test.stopTest();
    }
    // ** TEST PEO ** //
       static testmethod void testPEOProfiles(){
            UserRole userroleManager=new UserRole(Name='Oasis Manager'); 
            insert userroleManager; 
            Profile profManager = [select id from profile where name='HRS PEO Centric Administration'];
            User userManager = new User(Alias = 'Edward1',TimeZoneSidKey='America/Los_Angeles',EmailEncodingKey='UTF-8',LanguageLocaleKey='en_US' ,LocaleSidKey='en_US');
            userManager.firstName ='Edward1';
            userManager.lastName = 'Owen1';
            userManager.profileId = profManager.id;
            userManager.username =' eowen1@paychex.com.flsandbox1';
            userManager.email ='eowen1@oasispeo.com.invalid';
            userManager.UserRoleId =userroleManager.Id;
            userManager.Sales_Org__c='PEO';
            //userManager.Sales_Org__c='NSS';
            insert userManager;
    
            UserRole userrole=new UserRole(Name='Oasis SDR'); 
            insert userrole; 
            Profile prof = [select id from profile where name='HRS Sales Manager - SB'];
            User user1 = new User(Alias = 'kruff1',TimeZoneSidKey='America/Los_Angeles',EmailEncodingKey='UTF-8',LanguageLocaleKey='en_US' ,LocaleSidKey='en_US');
            user1.firstName ='Kent1';
            user1.lastName = 'Ruffo1';
            user1.profileId = prof.id;
            user1.username ='kruffo1@paychex.com.flsandbox2';
            user1.email ='kruffo1@oasispeo.com.invalid';
            user1.UserRoleId =userrole.Id;
            user1.managerId=userManager.Id;
            user1.Sales_Org__c='PEO';
            //user1.Sales_Org__c='NSS';
            insert user1;
    
            System.runAs(user1){
            test.starttest();
            Account acct = new Account(Name='Test Acct');
            insert acct;
    
            Map<String,Schema.RecordTypeInfo> opptyRTMap = RecordTypeHelper.getRecordTypeByNameMap('Opportunity');
            Id peoRTId = OpptyMethods.getRtIdFromMap('PEO Opportunity Record Type',opptyRTMap);
            Opportunity opp= new Opportunity(Name='Test Opp1', AccountId=acct.Id, CloseDate=Date.today().addDays(14), StageName='Qualified',Payroll_Platform__c = 'PEO', RecordTypeId=peoRTId);
            insert opp;
            
            test.stopTest();
    
            }
            
        }
    static testMethod void processSendtoHBOppsTest(){
        Integer numberUsers = 4;
        Case_HB_District_Queue_Mapping__c cs = new Case_HB_District_Queue_Mapping__c(Name='Field H&B IC Team 1',Districts__c='012,031,033',Queue_Name__c='Field H&B IC Team 1');
        insert cs;
        Group grp1 = new Group(Name='Field H&B IC Team 1',Type='Queue');
        insert grp1;
        
        Assignment_Group_Name__c agn1 = new Assignment_Group_Name__c(Name=grp1.Name,Use_Scheduler__c=true,Use_Weighting__c=true);
        insert agn1;
        
        Assignment_Group_Queues__c agq1 = new Assignment_Group_Queues__c(Name=grp1.Name, Assignment_Group_Name__c=agn1.Id);
        insert agq1;
        
        User[] users = [Select Id, Name, Email from User where IsActive=true and Assignment_Group_Active__c=true limit :numberUsers];
          Assignment_Groups__c[] assignGrps = new Assignment_Groups__c[]{};
          for (User u : users) {
             Assignment_Groups__c ag1 = new Assignment_Groups__c(Active__c='True',Group_Name__c=agn1.Id,User__c=u.Id);
             assignGrps.add(ag1);
          } // for (User u
          insert assignGrps;
         
        User u1 = [Select Id, Name from User where (District__c='012' or District__c='031' or District__c='033') and IsActive=true limit 1];
        
        Account acct = new Account(Name='Test Send to HB Acct');
        insert acct;
        Contact ctct = new Contact(FirstName='Test', LastName='Contact', AccountId=acct.Id);
        insert ctct;
        id hnbfOpptyRecTypeId = RecordTypeHelper.getRecordType(Label.HNBF_Opportunity_Record_Type,'Opportunity').getRecordTypeId();
        Opportunity oppty1 = new Opportunity(Name='Test Oppty1', RecordTypeId=hnbfOpptyRecTypeId,AccountId=acct.Id
                                             ,StageName=Label.OppStage_Qualified
                                             ,Send_to_H_B_Implementation__c='Yes'
                                             ,CloseDate=Date.today().addDays(30)
                                             ,OwnerId=u1.id);
        insert oppty1;
        OpportunityContactRole ocr1 = new OpportunityContactRole(ContactId=ctct.Id, OpportunityId=oppty1.Id, IsPrimary=true);
        insert ocr1;
        oppty1.StageName=Label.OppStage_Won;
        update oppty1; 
    } 
    //Reetesh
    static testMethod void testsetDefaultPayroll() {        
        User oppOwner = [SELECT Id FROM User WHERE Sales_Org__c = 'PAY' AND isActive = true LIMIT 1];
        Account acct = new Account(Name = 'Acct', OwnerId = oppOwner.Id);
        insert acct;
        Id coreRTId = RecordTypeHelper.getRecordType('Core Opportunity Record Type','Opportunity').getRecordTypeId();
        Opportunity oppty1 = new Opportunity(StageName=Label.OppStage_Qualified,CloseDate=Date.today(),Name = 'Oppty1', AccountId = acct.id, RecordTypeId=coreRTId, OwnerId = oppOwner.Id,OpportunityType__c='Payroll',Payroll_Platform__c='');
        Test.startTest();
        insert oppty1;
        // Opportunity oppty2 = [Select id,Payroll_Platform__c from Opportunity where id = :oppty1.id limit 1];
        oppty1.Payroll_Platform__c='';
        update oppty1;
        Test.stopTest();
        system.debug('Payroll platform>> '+ oppty1.Payroll_Platform__c + '  OpptyType >>'+ oppty1.OpportunityType__c);
        System.assertEquals('PAY', [Select id,Payroll_Platform__c from Opportunity where id = :oppty1.id limit 1].Payroll_Platform__c);
    }
    //Vinay
    static testMethod void updateOnboardingFormatTest(){
        Account acct = new Account(Name='TestHuckAccount');
        Id PCOppDSARecTypeId = RecordTypeHelper.getRecordType('PC Opportunity DSA Record Type','Opportunity').getRecordTypeId();
        Opportunity oppty1 = new Opportunity(Name='Test Oppty1334', RecordTypeId=PCOppDSARecTypeId,AccountId=acct.Id
                                            ,OpportunityType__c=''
                                            ,StageName=Label.OppStage_Qualified
                                            ,CloseDate=Date.today().addDays(30));
        insert oppty1;
        Test.startTest();
        oppty1.OpportunityType__c = 'PAS';
        update oppty1;
        System.assertEquals([SELECT Onboarding_Format__c FROM Opportunity WHERE Id =: oppty1.Id].Onboarding_Format__c, 'Direct Bill');
        Test.stopTest();
    }
    
    static testMethod void testOppUpdateRefPC(){    
        ID pcRT = Label.PCQuoteDataRecordTypeId;
        Id pcQueueId = [SELECT id FROM Group WHERE Type = 'Queue' and DeveloperName = 'P_C_Queue'].Id;
        
        Account acct = new Account(Name='ACCT1', Federal_ID_Number__c='86-7530913'
                                   ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        insert acct;
        
        Contact ctct = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct.id);
        insert ctct;
        
        Opportunity opp = new Opportunity(Name='PC OPP', AccountId=acct.Id, RecordTypeId = pcRT, OpportunityType__c = 'AUTO', HNBF_Sales_Type__c = 'New Case', 
                                          CloseDate=Date.today().addDays(7), StageName = 'Discovery', Probability = 40, Onboarding_Format__c = 'Direct Bill', Tarmika_Quote__c = 'https://bridge.tarmika.com');
        insert opp;
        
        Id caseRTId = RecordTypeHelper.getRecordType('Service Onboarding P&C Case', 'Case').getRecordTypeID();
        Case kase  = new Case(AccountId = acct.id, Opportunity__c = opp.id, recordtypeId = caseRTId);
        insert kase;
        
        Id refPCTypeId = RecordTypeHelper.getRecordType('P&C Onboarding', 'Reference_P_C__c').getRecordTypeID();
        Reference_P_C__c refPC = new Reference_P_C__c(Case_Lookup__c = kase.id, Opportunity_Lookup__c = opp.id, recordTypeId = refPCTypeId, P_C_Quoted_Tool__c = 'Huckleberry',
                                                      Onboarding_Format_Lookup__c = opp.Onboarding_Format__c, Current_Step__c = 'New', OwnerId = pcQueueId);
        insert refPC;
        System.debug('testOppUpdateRefPC opp='+opp);
        Reference_P_C__c checkRefPC = [Select Id, OwnerId, Owner.Name, Onboarding_Format_Lookup__c, P_C_Quoted_Tool__c, Current_Step__c, Opportunity_Lookup__c 
                                         from Reference_P_C__c where Id=:refPC.Id];
        System.debug('testOppUpdateRefPC checkRefPC='+checkRefPC);
        //initial insert of P&C Quote Data 
        PC_Quote_Data__c pcqD = new PC_Quote_Data__c(Opportunity__c = opp.Id, Prospect_Client__c=acct.Id, Opportunity_Type__c=opp.OpportunityType__c,Prospect_Client_Name__c=acct.Name,
                                                     Prospect_Client_Street__c=acct.ShippingStreet, Prospect_Client_City__c=acct.ShippingCity, Prospect_Client_State__c=acct.ShippingState,
                                                     Prospect_Client_Postal_Code__c=acct.ShippingPostalCode, Contact_First_Name__c=ctct.FirstName, Contact_Last_Name__c=ctct.LastName,
                                                     Contact_Phone_Number__c=ctct.Phone, Contact_Email_Address__c=ctct.Email);
        insert pcqD;
    /*           
        //inserting P&C Carrier Data with inital response from Huckleberry
        P_C_Carrier_Data__c pccD = new P_C_Carrier_Data__c(P_C_Quote_Data__c = pcqD.Id, Line_of_Business__c = 'CA', Carrier_Name__c = 'Farmers', Quote_Carrier_ID__c = '47-87451233', Quote_Request_ID__c = '8754210000', Quote_Premium__c = 1205.36, Quote_Status__c = 'Quoted');
        insert pccD;
        
        P_C_Carrier_Data__c pccD2 = [Select Id, P_C_Quote_Data__c, Opportunity__c, Opportunity__r.StageName, Line_of_Business__c, Carrier_Name__c, Quote_Carrier_ID__c, Quote_Premium__c, Quote_Status__c from P_C_Carrier_Data__c where Id =:pccD.Id];
        System.assertEquals('Quoted', pccD2.Quote_Status__c);
        
        //updating P&C Carrier Data with Quote Status response from Huckleberry - update opportunity
        pccD.Quote_Status__c = 'BINDABLE';
        update pccD;
        
        P_C_Carrier_Data__c pccD3 = [Select Id, P_C_Quote_Data__c, Opportunity__c, Opportunity__r.StageName, Line_of_Business__c, Carrier_Name__c, Quote_Carrier_ID__c, Quote_Premium__c, Quote_Status__c from P_C_Carrier_Data__c where Id =:pccD.Id];
        System.assertEquals('BINDABLE', pccD3.Quote_Status__c);
        System.assertEquals('Proposal', pccD3.Opportunity__r.StageName);
        
        //updating P&C Carrier Data with Policy Number adn Policy Bind Date response from Huckleberry - update opportunity
        pccD.Policy_Carrier_ID__c = '25478152';
        pccD.Policy_Bind_Date__c = Date.today();
        pccD.Renewal_Date__c = Date.today()+365;
        update pccD;
        
        P_C_Carrier_Data__c pccD4 = [Select Id, P_C_Quote_Data__c, Opportunity__c, Opportunity__r.StageName, Renewal_Date__c, Policy_Carrier_ID__c, Policy_Bind_Date__c from P_C_Carrier_Data__c where Id =:pccD.Id];
        System.assertEquals('25478152', pccD4.Policy_Carrier_ID__c);
        System.assertEquals(Date.today(), pccD4.Policy_Bind_Date__c);
        System.assertEquals('Sold-Submitted', pccD4.Opportunity__r.StageName);
        
        //update Opportunity to closed
        opp.StageName = 'Sold - Started';
        update opp;
        
        Reference_P_C__c refPCClosed = [Select Id, Case_Lookup__c, Case_Lookup__r.Status, Opportunity_Lookup__c, Opportunity_Lookup__r.StageName, Current_Step__c from Reference_P_C__c where Opportunity_Lookup__c =:opp.Id];
        System.assertEquals('Sold - Started', refPCClosed.Opportunity_Lookup__r.StageName);
        //System.assertEquals('Completed', refPCClosed.Case_Lookup__r.Status);
        //System.assertEquals('Completed', refPCClosed.Current_Step__c);
     */          
    } //testOppUpdateRefPC
    
} // class OpptyMethodsTest