/** Test methods for the ReferralAccountChkAcctOwner and ReferralAccountChkAcctBatch classes

* History
* -------
05/21/2018 Dan Carmen       Created
05/12/2020 Jake Hinds	   Referral Account Team
02/22/2022 Carrie Marciano  Added BenAdmin Holdout fields
03/04/2022 Dan Carmen       Clean up some ownership logic
12/23/2022 Jaipal       Added testleads() method to cover ReferralAccountChkAcctBatch class and ReferralAccountChkAcctOwner Class
02/14/2023 Eric Porter       Change employeee threshhold to a label
03/01/2023 Dan Carmen        Clean up check to see if it needs to evaluate referral source ownership
03/14/2023 Dan Carmen        Fix for If statment for CPAs to always check employee count
07/04/2023 Shilpa       	 APR0152866: Updated method 'testAccountTrigger'
09/08/2023 Dan Carmen        Do not run the referral ownership immediately if running as sfdc data.

*/
@isTest
private class ReferralAccountChkAcctOwnerTest {
    
    @testSetup
    public static void setupTestData() {
        TriggerMethodsTest.createTriggerSetting('ReferralAccountBefore', true, false, false, false, new String[]{'ReferralAccountChkAcctOwner'});
        TriggerMethodsTest.createTriggerSetting('AccountBefore', true, false, false, false, new String[]{'ReferralAccountChkAcctOwner'});
        TriggerMethodsTest.createTriggerSetting('AccountAfter', false, true, false, false, new String[]{'ReferralAccountChkAcctOwner'});
        TriggerMethodsTest.createTriggerSetting('LeadBefore', true, false, false, false, new String[]{'ReferralAccountChkAcctOwner'});
        TriggerMethodsTest.createTriggerSetting('LeadAfter', false, true, false, false, new String[]{'ReferralAccountChkAcctOwner'});
        TriggerMethodsTest.saveSetupClasses();
        
        HoldOut_ExpirationDates__c hoPAY = new HoldOut_ExpirationDates__c(Name='PAY',Sales_Org__c='PAY',Account_Hold_Out__c='Hold_Out__c',Account_Hold_Out_Date__c='Hold_Out_Expiration__c',HoldOutReasonFld__c='Permanent_Hold_Out_Description__c',Account_Owner__c='OwnerId',AccountTeamRole__c=null);
        HoldOut_ExpirationDates__c hoHNBF = new HoldOut_ExpirationDates__c(Name='HNBF',Sales_Org__c='HNBF',Account_Hold_Out__c='HNBF_Hold_Out__c',Account_Hold_Out_Date__c='HNBF_Hold_Out_Expiration__c',HoldOutReasonFld__c='HNBF_Permanent_Hold_Out_Description__c',Account_Owner__c='HNBF_Account_Owner__c',AccountTeamRole__c='H&B Partner');
        HoldOut_ExpirationDates__c hoBenAdmin = new HoldOut_ExpirationDates__c(Name='BenAdmin',Sales_Org__c='BenAdmin',Account_Hold_Out__c='BenAdmin_Hold_Out__c',Account_Hold_Out_Date__c='BenAdmin_Hold_Out_Expiration__c',HoldOutReasonFld__c='BenAdmin_Hold_Out_Reason__c',AccountTeamRole__c='BenAdmin Partner'); 
        HoldOut_ExpirationDates__c hoMS = new HoldOut_ExpirationDates__c(Name='MS',Sales_Org__c='MS',Account_Hold_Out__c='MS_Hold_Out__c',Account_Hold_Out_Date__c='MS_Hold_Out_Expiration__c',HoldOutReasonFld__c='MS_Permanent_Hold_Out_Description__c',AccountTeamRole__c='Merchant Services Representative');
        HoldOut_ExpirationDates__c leadhoPAY = new HoldOut_ExpirationDates__c(Name='PAY1',Sales_Org__c='PAY',Lead_Hold_Out__c='Hold_Out__c',Lead_Hold_Out_Date__c='Hold_Out_Expiration__c',Lead_Hold_Out_Reason_Fld__c='Hold_Out_Reason__c',Lead_Owner__c='OwnerId');
        HoldOut_ExpirationDates__c[] hos = new HoldOut_ExpirationDates__c[]{hoPAY,hoHNBF,hoMS, leadhoPAY};
            insert hos;
    } // setupTestData
    
    static testMethod void testDedicatedRepsBatch() {
        ReferralAccountChkAcctOwner.BYPASS_CURRENT_CLIENT = true;
        ReferralAccountChkAcctOwner.EMP_THRESHHOLD=50;
        
        User runningUser = UserHelper.getRunningUser();
        
        // select a bunch of users to set as dedicated reps.
        User[] payUsers = [Select Id, Name,Sales_Org__c from User where UserRoleId != null and IsActive=true and Sales_Org__c = 'PAY' and Job_Name__c=:UserHelper.JOB_REP limit 3];
        User hnbfUser = [Select Id, Name,Sales_Org__c from User where UserRoleId != null and IsActive=true and Sales_Org__c = 'HNBF' and Job_Name__c=:UserHelper.JOB_REP limit 1];
        User msUser = [Select Id, Name,Sales_Org__c from User where UserRoleId != null and IsActive=true and Sales_Org__c = 'MS' and Job_Name__c=:UserHelper.JOB_REP limit 1];
        // select a couple of inactive to check this case
        User[] inactiveUsers = [Select Id, Name,Sales_Org__c from User where UserRoleId != null and IsActive=false and Job_Name__c=:UserHelper.JOB_REP limit 2];
        
        System.debug('testDedicatedReps1 msUser='+msUser.Id+' name='+msUser.Name);
        System.debug('testDedicatedReps1 hnbfUser='+hnbfUser.Id+' name='+hnbfUser.Name);
        System.debug('testDedicatedReps1 payUser 0='+payUsers[0].Id+' name='+payUsers[0].Name);
        System.debug('testDedicatedReps1 payUser 1='+payUsers[1].Id+' name='+payUsers[1].Name);
        System.debug('testDedicatedReps1 payUser 2='+payUsers[2].Id+' name='+payUsers[2].Name);
        
        Account acct1a = new Account(Name='Test Account1a', OwnerId=payUsers[2].Id, NumberOfEmployees=25, Employees__c=25);
        Account acct1b = new Account(Name='Test Account1b', OwnerId=payUsers[2].Id, NumberOfEmployees=25, Employees__c=25);
        Account acct2a = new Account(Name='Test Account2a', OwnerId=payUsers[2].Id, NumberOfEmployees=25, Employees__c=25);
        Account acct3 = new Account(Name='Test Account3', OwnerId=payUsers[2].Id, NumberOfEmployees=25, Employees__c=25);
        Account acct4 = new Account(Name='Test Account4', OwnerId=payUsers[2].Id, NumberOfEmployees=25, Employees__c=25);
        Account acct5 = new Account(Name='Test Account5', OwnerId=payUsers[2].Id, NumberOfEmployees=25, Employees__c=25);
        Account acct6 = new Account(Name='Test Account6', OwnerId=payUsers[2].Id, NumberOfEmployees=25, Employees__c=25);
        Account acct7 = new Account(Name='Test Account7', OwnerId=payUsers[2].Id, NumberOfEmployees=25, Employees__c=25);
        Account acct8 = new Account(Name='Test Account8', OwnerId=payUsers[2].Id, Hold_Out__c=true, Hold_Out_Expiration__c=Date.today().addDays(30), NumberOfEmployees=25, Employees__c=25);
        Account acct9 = new Account(Name='Test Account9', OwnerId=payUsers[2].Id, Hold_Out__c=true, Permanent_Hold_Out_Description__c='This is a Hold Out', NumberOfEmployees=25, Employees__c=25);
        Account acct10 = new Account(Name='Test Account10', OwnerId=payUsers[2].Id, Hold_Out__c=true, Permanent_Hold_Out_Description__c=ReferralAccountChkAcctOwner.HOLD_OUT_IA, NumberOfEmployees=25, Employees__c=25);
        Account acct11 = new Account(Name='Test Account11', OwnerId=payUsers[2].Id, Hold_Out__c=true, Permanent_Hold_Out_Description__c=ReferralAccountChkAcctOwner.HOLD_OUT_IA, NumberOfEmployees=25, Employees__c=25);
        Account[] accts = new Account[]{acct1a,acct1b,acct2a,acct3,acct4,acct5,acct6,acct7,acct8,acct9,acct10,acct11};
            ZipCheckOwner.SKIP_TRIGGERS=true;
        insert accts;
        
        id refAcctRT5 = RecordTypeHelper.getRecordType('Sales Channel Referral Account Record Type','Referral_Account__c').getRecordTypeId();  
        
        // create a couple of parent referral accounts.
        Referral_Account__c refAcctParent1 = new Referral_Account__c(Name='Test Parent1');
        Referral_Account__c refAcctParent2 = new Referral_Account__c(Name='Test Parent2');
        Referral_Account__c[] refAcctParents = new Referral_Account__c[]{refAcctParent1,refAcctParent2};
            TriggerMethods.clearVariables();
        insert refAcctParents;
        
        System.debug('testDedicatedReps1 refAcctParent1 dedicated='+refAcctParent1.DedicatedRep__c);
        System.debug('testDedicatedReps1 refAcctParent2 dedicated='+refAcctParent2.DedicatedRep__c);
        
        Referral_Account__c refAcctChild1a = new Referral_Account__c(Name='Child a of Parent1', Parent_Referral_Account__c=refAcctParent1.Id);
        Referral_Account__c refAcctChild1b = new Referral_Account__c(Name='Child b of Parent1', Parent_Referral_Account__c=refAcctParent1.Id);
        Referral_Account__c refAcctChild2a = new Referral_Account__c(Name='Child a of Parent2', Parent_Referral_Account__c=refAcctParent2.Id);
        Referral_Account__c refAcct3 = new Referral_Account__c(Name='Ref Acct 3');
        // there's a field validation rule looking for the record type for a strategic/national account.
        Referral_Account__c refAcct4 = new Referral_Account__c(Name='Ref Acct 4', RecordTypeId=refAcctRT5);
        Referral_Account__c refAcct5 = new Referral_Account__c(Name='Ref Acct 5');
        // this should not prompt an ownership change since the owner is inactive
        Referral_Account__c refAcct6 = new Referral_Account__c(Name='Ref Acct 6');
        // no dedicated rep so no change - set the flag so it falls into the batch.
        Referral_Account__c refAcct7 = new Referral_Account__c(Name='Ref Acct 7', DedicatedRepChanged__c=true);
        Referral_Account__c[] refAccts = new Referral_Account__c[]{refAcctChild1a,refAcctChild1b,refAcctChild2a,refAcct3,refAcct4,refAcct5,refAcct6,refAcct7};
            TriggerMethods.clearVariables();
        insert refAccts;
        
        Referral_Account_Team__c ratForParentRA1 = new Referral_Account_Team__c(Referral_Account__c = refAcctParent1.Id,Team_Member_Name__c=msUser.Id);
        Referral_Account_Team__c ratForParentRA2 = new Referral_Account_Team__c(Referral_Account__c = refAcctParent2.Id,Team_Member_Name__c=hnbfUser.Id);
        Referral_Account_Team__c ratForRA3= new Referral_Account_Team__c(Referral_Account__c = refAcct3.Id,Team_Member_Name__c=payUsers[0].Id);
        Referral_Account_Team__c ratForRA4= new Referral_Account_Team__c(Referral_Account__c = refAcct4.Id,Team_Member_Name__c=payUsers[1].Id);
        Referral_Account_Team__c ratForRA5= new Referral_Account_Team__c(Referral_Account__c = refAcct5.Id,Team_Member_Name__c=payUsers[2].Id);
        Referral_Account_Team__c ratForRA6= new Referral_Account_Team__c(Referral_Account__c = refAcct6.Id,Team_Member_Name__c=inactiveUsers[0].Id);
        Referral_Account_Team__c[] rats = new Referral_Account_Team__c[]{ratForParentRA1,ratForParentRA2,ratForRA3,ratForRA4,ratForRA5,ratForRA6};
            insert rats;
        //doing this to get 'Account_Owner__c' formula field from rats
        //Formula.recalculateFormulas(rats);
        
        // make sure the flag is set on the referral accounts we want to be in the batch.
        System.assertEquals(7, [Select count() from Referral_Account__c where DedicatedRepChanged__c=true]);
        
        Referral_Contact__c refCtctChild1a = new Referral_Contact__c(Referral_Account__c=refAcctChild1a.Id, Name='Test Ctct1a');
        Referral_Contact__c refCtctChild1b = new Referral_Contact__c(Referral_Account__c=refAcctChild1b.Id, Name='Test Ctct1b');
        Referral_Contact__c refCtctChild2a = new Referral_Contact__c(Referral_Account__c=refAcctChild2a.Id, Name='Test Ctct2a');
        Referral_Contact__c refCtct3 = new Referral_Contact__c(Referral_Account__c=refAcct3.Id, Name='Test Ctct3');
        Referral_Contact__c refCtct4 = new Referral_Contact__c(Referral_Account__c=refAcct4.Id, Name='Test Ctct4');
        Referral_Contact__c refCtct5 = new Referral_Contact__c(Referral_Account__c=refAcct5.Id, Name='Test Ctct5');
        Referral_Contact__c refCtct6 = new Referral_Contact__c(Referral_Account__c=refAcct6.Id, Name='Test Ctct6');
        Referral_Contact__c refCtct7 = new Referral_Contact__c(Referral_Account__c=refAcct7.Id, Name='Test Ctct7');
        Referral_Contact__c[] refCtcts = new Referral_Contact__c[]{refCtctChild1a,refCtctChild1b,refCtctChild2a,refCtct3,refCtct4,refCtct5,refCtct6,refCtct7};
            TriggerMethods.clearVariables();
        insert refCtcts;
        
        acct1a.Banker_Name_Ref__c = refCtctChild1a.Id;
        acct1b.Banker_Name_Ref__c = refCtctChild1b.Id;
        acct2a.CPA_Name_Ref__c = refCtctChild2a.Id;
        acct3.Insurance_Broker_Name_Ref__c = refCtct3.Id;
        acct4.Referral_National_Account__c = refAcct4.Id;
        acct5.CPA_Name_Ref__c = refCtct3.Id;
        acct5.Banker_Name_Ref__c = refCtct5.Id;
        acct5.Referral_National_Account__c = refAcct4.Id;
        acct6.CPA_Name_Ref__c = refCtct6.Id;
        acct7.Banker_Name_Ref__c = refCtct7.Id;
        // neither of these should change ownership because of the existing holdouts.
        acct8.CPA_Name_Ref__c = refCtct3.Id;
        acct9.CPA_Name_Ref__c = refCtct3.Id;
        // this should change owner because the existing holdout is at a lower priority
        acct10.CPA_Name_Ref__c = refCtct3.Id;
        // we want to remove the hold out on this record.
        acct11.CPA_Name_Ref__c = refCtct7.Id;
        
        // todo - once the field change is running in the trigger we want to disable it here so it's picked up by the batch
        ReferralAccountChkAcctOwner.SKIP_RFRL_OWNERSHIP_TRIGGER = true;
        TriggerMethods.clearVariables();
        update accts;
        
        Test.startTest();
        ReferralAccountChkAcctBatch racab = new ReferralAccountChkAcctBatch();
        database.executeBatch(racab, 30);
        Test.stopTest();
        
        Map<Id,Account> acctMap = getAcctMap(accts);
        verifyAccountFromRAT('acct1a', acctMap.get(acct1a.Id), msUser, ratForParentRA1, true, ReferralAccountChkAcctOwner.HOLD_OUT_BANK);
        verifyAccountFromRAT('acct1b', acctMap.get(acct1b.Id), msUser, ratForParentRA1, true, ReferralAccountChkAcctOwner.HOLD_OUT_BANK);
        verifyAccountFromRAT('acct2a', acctMap.get(acct2a.Id), hnbfUser, ratForParentRA2, true, ReferralAccountChkAcctOwner.HOLD_OUT_CPA);
        verifyAccountFromRAT('acct3', acctMap.get(acct3.Id), payUsers[0], ratForRA3, true, ReferralAccountChkAcctOwner.HOLD_OUT_IA);
        verifyAccountFromRAT('acct4', acctMap.get(acct4.Id), payUsers[1], ratForRA4, true, ReferralAccountChkAcctOwner.HOLD_OUT_SA);
        verifyAccountFromRAT('acct5', acctMap.get(acct5.Id), payUsers[1], ratForRA5, true, ReferralAccountChkAcctOwner.HOLD_OUT_SA);
        verifyAccountFromRAT('acct6', acctMap.get(acct6.Id), payUsers[2], ratForRA6, false, null);
        verifyAccountFromRAT('acct7', acctMap.get(acct7.Id), payUsers[2], null, false, null);
        verifyAccountFromRAT('acct8', acctMap.get(acct8.Id), payUsers[2], ratForRA3, true, null);
        verifyAccountFromRAT('acct9', acctMap.get(acct9.Id), payUsers[2], ratForRA3, true, acct9.Permanent_Hold_Out_Description__c);
        verifyAccountFromRAT('acct10', acctMap.get(acct10.Id), payUsers[0], ratForRA3, true, ReferralAccountChkAcctOwner.HOLD_OUT_CPA);
        verifyAccountFromRAT('acct11', acctMap.get(acct11.Id), payUsers[2], null, false, null);
        
        System.assertEquals(0,[select count() from Referral_Account__c where DedicatedRepChanged__c=true]);
        
    } // testDedicatedRepsBatch
    
    public static Map<Id,Account> getAcctMap(Account[] accts) {
        Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Name, OwnerId
                                                       ,EvaluateRefAcctOwner__c, ProcessNotes__c, CurrentClient__c
                                                       ,Hold_Out__c,Hold_Out_Expiration__c, Permanent_Hold_Out_Description__c 
                                                       ,HNBF_Account_Owner__c,HNBF_Hold_Out__c,HNBF_Hold_Out_Expiration__c,HNBF_Permanent_Hold_Out_Description__c
                                                       ,MS_Hold_Out__c,MS_Hold_Out_Expiration__c,MS_Permanent_Hold_Out_Description__c
                                                       ,(SELECT Id,UserId,AccountId,TeamMemberRole FROM AccountTeamMembers)
                                                       from Account where Id in :accts]);
        return acctMap;
    } // getAcctMap
    
    public static Map<Id,Lead> getLeadMap(Lead[] leads) {
        Map<Id,Lead> leadMap = new Map<Id,Lead>([Select Id, Name, OwnerId
                                                       ,EvaluateRefAcctOwner__c, ProcessNotes__c
                                                       ,Hold_Out__c,Hold_Out_Expiration__c
                                                       ,Referral_Contact__c, LastNameLocal
                                                       ,Referral_National_Account__c
                                                       from Lead where Id in :leads]);
        return leadMap;
    } // getLeadMap
    
    static testMethod void testAccountTrigger() {
        ReferralAccountChkAcctOwner.EMP_THRESHHOLD=50;
        // select a bunch of users to set as dedicated reps.
        User[] payUsers = [Select Id, Name,Sales_Org__c from User where UserRoleId != null and IsActive=true and Sales_Org__c = 'PAY' and Job_Name__c=:UserHelper.JOB_REP limit 3];
        User hnbfUser = [Select Id, Name,Sales_Org__c from User where UserRoleId != null and IsActive=true and Sales_Org__c = 'HNBF' and Job_Name__c=:UserHelper.JOB_REP limit 1];
        User[] msUsers = [Select Id, Name,Sales_Org__c from User where UserRoleId != null and IsActive=true and Sales_Org__c = 'MS' and Job_Name__c=:UserHelper.JOB_REP limit 2];
        // select a couple of inactive to check this case
        User[] inactiveUsers = [Select Id, Name,Sales_Org__c from User where UserRoleId != null and IsActive=false and Job_Name__c=:UserHelper.JOB_REP limit 2];
        
        id refAcctRT = RecordTypeHelper.getRecordType('Sales Channel Referral Account Record Type','Referral_Account__c').getRecordTypeId();
        Referral_Account__c parentRefAcct = new Referral_Account__c(Name='Parent RA',RecordTypeId = refAcctRT);
        ReferralAccountMethods.SKIP_TRIGGERS=true;
        insert parentRefAcct; 
        // create referral accounts.
        Referral_Account__c refAcct1 = new Referral_Account__c(Name='Test Acct1');
        Referral_Account__c refAcct2 = new Referral_Account__c(Name='Test Acct2');
        Referral_Account__c refAcct3 = new Referral_Account__c(Name='Test Acct3',Parent_Referral_Account__c=parentRefAcct.Id,RecordTypeId = refAcctRT);
		Referral_Account__c refAcct4 = new Referral_Account__c(Name='Test Acct4',Referral_Source_Business_Type__c='Strategic Account',ReferralSourceSubType__c='Field');
        Referral_Account__c[] refAccts = new Referral_Account__c[]{refAcct1,refAcct2,refAcct3,refAcct4};
            insert refAccts;       
        
        Referral_Account_Team__c ratForRA1= new Referral_Account_Team__c(Referral_Account__c = refAcct1.Id,Team_Member_Name__c=payUsers[0].Id);
        Referral_Account_Team__c ratForRA2= new Referral_Account_Team__c(Referral_Account__c = refAcct2.Id,Team_Member_Name__c=msUsers[1].Id);
        Referral_Account_Team__c ratForRA3= new Referral_Account_Team__c(Referral_Account__c = parentRefAcct.Id,Team_Member_Name__c=msUsers[1].Id);
		Referral_Account_Team__c ratForRA4= new Referral_Account_Team__c(Referral_Account__c = refAcct4.Id,Team_Member_Name__c=payUsers[0].Id);
        Referral_Account_Team__c[] rats = new Referral_Account_Team__c[]{ratForRA1,ratForRA2,ratForRA3,ratForRA4};
            insert rats;
        //doing this to get 'Account_Owner__c' formula field from rats
        //Formula.recalculateFormulas(rats);
        
        Referral_Contact__c refCtct1 = new Referral_Contact__c(Referral_Account__c=refAcct1.Id, Name='Test Ctct1');
        Referral_Contact__c refCtct2 = new Referral_Contact__c(Referral_Account__c=refAcct2.Id, Name='Test Ctct2');
        Referral_Contact__c refCtct3 = new Referral_Contact__c(Referral_Account__c=refAcct3.Id, Name='Test Ctct3');
		Referral_Contact__c refCtct4 = new Referral_Contact__c(Referral_Account__c=refAcct4.Id, Name='Test Ctct4');
        Referral_Contact__c[] refCtcts = new Referral_Contact__c[]{refCtct1,refCtct2,refCtct3,refCtct4};
            insert refCtcts;
        
        ReferralAccountChkAcctOwner.BYPASS_CURRENT_CLIENT = true;
        Utilities.SKIP_FUTURE = true;
        User runningUser = UserHelper.getRunningUser();
        Account acct1 = new Account(Name='Test Account1', OwnerId=payUsers[2].Id, NumberOfEmployees=25, Employees__c=25);
        Account acct2 = new Account(Name='Test Account2', OwnerId=payUsers[2].Id, CPA_Name_Ref__c=refCtct2.Id, NumberOfEmployees=25, Employees__c=25);
        Account acct3 = new Account(Name='Test Account3', OwnerId=payUsers[2].Id, Hold_Out__c=true, Hold_Out_Expiration__c=Date.today().addDays(30), NumberOfEmployees=25, Employees__c=25);
        Account acct4 = new Account(Name='Test Account4', OwnerId=payUsers[2].Id, NumberOfEmployees=60, Employees__c=60);
        Account acct5 = new Account(Name='Test Account5', OwnerId=payUsers[2].Id, NumberOfEmployees=25, Employees__c=25);
        Account acct6 = new Account(Name='Test Account6', OwnerId=payUsers[2].Id, NumberOfEmployees=25, Employees__c=25);
        Account acct7 = new Account(Name='Test Account6', OwnerId=payUsers[2].Id, NumberOfEmployees=25, Employees__c=25);
		Account acct8 = new Account(Name='Test Account8', OwnerId=payUsers[2].Id, NumberOfEmployees=25, Employees__c=25);
        Account[] accts = new Account[]{acct1,acct2,acct3, acct4,acct5,acct6,acct7,acct8};
            TriggerMethods.clearVariables();
        insert accts;
        
        AccountTeamMember atm = new AccountTeamMember(AccountId=acct5.Id,UserId=msUsers[0].Id,TeamMemberRole='Merchant Services Representative');
        insert atm;
        
        Map<Id,Account> acctMap = getAcctMap(accts);
        
        verifyAccountFromRAT('acct1', acctMap.get(acct1.Id), payUsers[2], null, false, null);
        verifyAccountFromRAT('acct2', acctMap.get(acct2.Id), msUsers[1], ratForRA2, true, ReferralAccountChkAcctOwner.HOLD_OUT_CPA);
        verifyAccountFromRAT('acct3', acctMap.get(acct3.Id), payUsers[2], null, true, null);
        verifyAccountFromRAT('acct4', acctMap.get(acct4.Id), payUsers[2], null, false, null);
        
        acct1.Broker_Name_Ref__c = refCtct1.Id;
        acct2.CPA_Name_Ref__c = refCtct1.Id;
        acct3.CPA_Name_Ref__c = refCtct1.Id;
        acct4.Insurance_Broker_Name_Ref__c = refCtct1.Id;
        acct5.Insurance_Broker_Name_Ref__c = refCtct3.Id;
        acct6.Broker_Name_Ref__c = refCtct3.Id;
        acct7.Referral_National_Account__c = refAcct3.Id;
		acct8.Referral_National_Account__c = refAcct4.Id;
        TriggerMethods.clearVariables();
        update accts;
        
        acctMap = getAcctMap(accts);
        verifyAccountFromRAT('acct1', acctMap.get(acct1.Id), payUsers[0], ratForRA1, true, ReferralAccountChkAcctOwner.HOLD_OUT_BROKER);
        verifyAccountFromRAT('acct2', acctMap.get(acct2.Id), payUsers[0], ratForRA1, true, ReferralAccountChkAcctOwner.HOLD_OUT_CPA);
        verifyAccountFromRAT('acct3', acctMap.get(acct3.Id), payUsers[2], null, true, null);
        verifyAccountFromRAT('acct4', acctMap.get(acct4.Id), payUsers[2], null, false, null);
        verifyAccountFromRAT('acct5', acctMap.get(acct5.Id), msUsers[1], ratForRA3, true, ReferralAccountChkAcctOwner.HOLD_OUT_IA);
        verifyAccountFromRAT('acct6', acctMap.get(acct6.Id), msUsers[1], ratForRA3, true, ReferralAccountChkAcctOwner.HOLD_OUT_BROKER);
        verifyAccountFromRAT('acct7', acctMap.get(acct7.Id), msUsers[1], ratForRA3, true, ReferralAccountChkAcctOwner.HOLD_OUT_SA);
        
        acct1.Broker_Name_Ref__c = refCtct2.Id;
        acct2.CPA_Name_Ref__c = null;
        acct3.CPA_Name_Ref__c = refCtct2.Id;
        acct4.NumberOfEmployees = 45;
        acct4.Employees__c = 45;
        Utilities.SKIP_FUTURE = false;
        Test.startTest();
        TriggerMethods.clearVariables();
        System.debug('testAccountTrigger before last update');
        update new Account[]{acct1,acct2,acct3,acct4};
        Test.stopTest();
        
        acctMap = getAcctMap(accts);
        verifyAccountFromRAT('acct1', acctMap.get(acct1.Id), msUsers[1], ratForRA2, true, ReferralAccountChkAcctOwner.HOLD_OUT_BROKER);
        //verifyAccountFromRAT('acct2', acctMap.get(acct2.Id), payUsers[2], null, false, null);
        verifyAccountFromRAT('acct3', acctMap.get(acct3.Id), payUsers[2], null, true, null);
        verifyAccountFromRAT('acct4', acctMap.get(acct4.Id), payUsers[0], ratForRA1, true, ReferralAccountChkAcctOwner.HOLD_OUT_IA);
        
    } // testAccountTrigger
    
    static testMethod void testSMBChannelChanges() {
        ReferralAccountChkAcctOwner.EMP_THRESHHOLD=50;
        User[] payUsers = [Select Id, Name,Sales_Org__c from User where UserRoleId != null and IsActive=true and Sales_Org__c = 'PAY' and Job_Name__c=:UserHelper.JOB_REP limit 3];
        User hnbfUser = [Select Id, Name,Sales_Org__c from User where UserRoleId != null and IsActive=true and Sales_Org__c = 'HNBF' and Job_Name__c=:UserHelper.JOB_REP limit 1];
        User[] msUsers = [Select Id, Name,Sales_Org__c from User where UserRoleId != null and IsActive=true and Sales_Org__c = 'MS' and Job_Name__c=:UserHelper.JOB_REP limit 2];
        User[] smbChannelUsers = [Select Id, Name, Sales_Org__c, Sales_Division__c from User where UserRoleId != null and IsActive=true and Sales_Org__c = 'PAY' and Sales_Division__c='SMB Channel' limit 1];
        
        id refAcctRT = RecordTypeHelper.getRecordType('Sales Channel Referral Account Record Type','Referral_Account__c').getRecordTypeId();
        Referral_Account__c parentRefAcct = new Referral_Account__c(Name='Parent RA',RecordTypeId = refAcctRT);
        insert parentRefAcct; 
        
        Referral_Account__c refAcct1 = new Referral_Account__c(Name='Test Acct1');
        Referral_Account__c refAcct2 = new Referral_Account__c(Name='Test Acct2');
        Referral_Account__c refAcct3 = new Referral_Account__c(Name='Test Acct3',Parent_Referral_Account__c=parentRefAcct.Id,RecordTypeId = refAcctRT);
        Referral_Account__c[] refAccts = new Referral_Account__c[]{refAcct1,refAcct2,refAcct3};
            insert refAccts;
        
        Referral_Account_Team__c ratForRA1= new Referral_Account_Team__c(Referral_Account__c = refAcct1.Id,Team_Member_Name__c=payUsers[0].Id);
        Referral_Account_Team__c ratForRA2= new Referral_Account_Team__c(Referral_Account__c = refAcct2.Id,Team_Member_Name__c=msUsers[1].Id);
        Referral_Account_Team__c ratForRA3= new Referral_Account_Team__c(Referral_Account__c = parentRefAcct.Id,Team_Member_Name__c=msUsers[1].Id);
        Referral_Account_Team__c[] rats = new Referral_Account_Team__c[]{ratForRA1,ratForRA2,ratForRA3};
            insert rats;
        //doing this to get 'Account_Owner__c' formula field from rats
        Formula.recalculateFormulas(rats);
        
        Referral_Contact__c refCtct1 = new Referral_Contact__c(Referral_Account__c=refAcct1.Id, Name='Test Ctct1');
        Referral_Contact__c refCtct2 = new Referral_Contact__c(Referral_Account__c=refAcct2.Id, Name='Test Ctct2');
        Referral_Contact__c refCtct3 = new Referral_Contact__c(Referral_Account__c=refAcct3.Id, Name='Test Ctct3');
        Referral_Contact__c[] refCtcts = new Referral_Contact__c[]{refCtct1,refCtct2,refCtct3};
            insert refCtcts;
        
        //ReferralAccountChkAcctOwner.BYPASS_CURRENT_CLIENT = true;
        Utilities.SKIP_FUTURE = true;
        User runningUser = UserHelper.getRunningUser();
        Account acct1 = new Account(Name='Test Account1', OwnerId=smbChannelUsers[0].Id, CPA_Name_Ref__c=refCtct2.Id, NumberOfEmployees=25, Employees__c=25, Type='Flex Client', Bis_ID__c=1, First_Run_Date__c=System.today());
        Account acct2 = new Account(Name='Test Account2', OwnerId=smbChannelUsers[0].Id, CPA_Name_Ref__c=refCtct3.Id, NumberOfEmployees=25, Employees__c=25, Type='Flex Client', Bis_ID__c=2, First_Run_Date__c=System.today());
        Account[] accts = new Account[]{acct1, acct2};
            TriggerMethods.clearVariables();
        System.debug('Inserting Account1');
        insert accts;
        
        List<Account> accts1 = [SELECT Id, Name, CurrentClient__c, Lost_Date__c FROM Account WHERE Id=:acct1.Id OR Id=:acct2.Id];
        System.debug('1 ReferralAccountChkAcctOwnerTest acct1.CurrentClient__c='+acct1.CurrentClient__c);
        accts1[0].Type = 'Lost Client';
        accts1[1].Type = 'Lost Client';
        Test.startTest();
        TriggerMethods.clearVariables();
        update accts1;
        Test.stopTest();
        
        List<Account> accts2 = [SELECT Id, Name, CurrentClient__c, Lost_Date__c FROM Account WHERE Id=:acct1.Id OR Id=:acct2.Id];
        accts.clear();
        accts.add(accts2[0]);
        accts.add(accts2[1]);
        
        Map <Id, Account> acctMap = getAcctMap(accts);
        verifyAccountFromRAT('acct1', acctMap.get(acct1.Id), smbChannelUsers[0], null, false, null);
        verifyAccountFromRAT('acct2', acctMap.get(acct2.Id), smbChannelUsers[0], null, false, null);
    } // testSMBChannelChanges
    
    //TO DO, get the hold out setting, check owner or account team along with holdout fields.  Update all methods to use this over verifyAccount
    public static void verifyAccountFromRAT(String testName, Account acct, User owner, Referral_Account_Team__c rat, Boolean hasHoldOut, String holdOutReason) {
        ReferralAccountChkAcctOwner.EMP_THRESHHOLD=50;
        HoldOut_ExpirationDates__c hoed = HoldOut_ExpirationDates__c.getInstance(owner.Sales_Org__c);
        Map<String,Id> acctTeamMap = new Map<String,Id>(); 
        System.debug('verifyAccount testName='+testName+' acct='+acct+' hoed='+hoed);
        System.assertEquals(hasHoldOut, (Boolean)acct.get(hoed.Account_Hold_Out__c));
        System.assertEquals(holdOutReason, (String)acct.get(hoed.HoldOutReasonFld__c));
        if(acct.AccountTeamMembers!=null && !acct.AccountTeamMembers.isEmpty()){
            for(AccountTeamMember at : acct.AccountTeamMembers){
                acctTeamMap.put(at.TeamMemberRole,at.UserId);
            }
        }
        if(rat!=null && String.isNotBlank(rat.Account_Owner__c) && rat.Account_Owner__c.StartsWith('AT ')) {
            system.assertEquals(acctTeamMap.get(rat.Account_Owner__c.subStringAfter('AT ')),owner.Id);
        }
        else if(rat!=null && String.isNotBlank(rat.Account_Owner__c)) {
            system.assertEquals(owner.Id,(Id)acct.get(rat.Account_Owner__c));
        }
        else if(rat==null && String.isNotBlank(hoed.Account_Owner__c)) {
            system.assertEquals(owner.Id,(Id)acct.get(hoed.Account_Owner__c));
        }
    } // verifyAccount
    
    public static void verifyLeadFromRAT(String testName, Lead lead, User owner, Referral_Account_Team__c rat, Boolean hasHoldOut, String holdOutReason, Date holdOutExpirationDate) {
        ReferralAccountChkAcctOwner.EMP_THRESHHOLD=50;
        HoldOut_ExpirationDates__c hoed = HoldOut_ExpirationDates__c.getInstance(owner.Sales_Org__c);
        Map<String,Id> leadTeamMap = new Map<String,Id>(); 
        System.debug('verifylead testName='+testName+' lead='+lead+' hoed='+hoed);
        if(hoed.Lead_Hold_Out__c!= null){
        System.assertEquals(hasHoldOut, (Boolean)lead.get(hoed.Lead_Hold_Out__c));
        System.assertEquals(holdOutReason, (String)lead.get(hoed.Lead_Hold_Out_Reason_Fld__c));
        System.assertEquals(holdOutExpirationDate, (Date)lead.get(hoed.Lead_Hold_Out_Date__c));
        }
        if(rat!=null && String.isNotBlank(rat.Account_Owner__c) && rat.Account_Owner__c.StartsWith('AT')) {
            system.assertEquals(leadTeamMap.get(rat.Account_Owner__c.subStringAfter('AT ')),owner.Id);
        }
        else if(rat!=null && String.isNotBlank(rat.Account_Owner__c)) {
            system.assertEquals(owner.Id,(Id)lead.get(rat.Account_Owner__c));
        }
        else if(rat==null && String.isNotBlank(hoed.Lead_Owner__c)) {
            system.assertEquals(owner.Id,(Id)lead.get(hoed.Lead_Owner__c));
        }
    } // verifyLeadFromRAT
    
    static testMethod void testleads() {
        ReferralAccountChkAcctOwner.BYPASS_CURRENT_CLIENT = true;
        ReferralAccountChkAcctOwner.EMP_THRESHHOLD=50;
        
        User runningUser = UserHelper.getRunningUser();
        
        // select a bunch of users to set as dedicated reps.
        User[] payUsers = [Select Id, Name,Sales_Org__c from User where UserRoleId != null and IsActive=true and Sales_Org__c = 'PAY' and Job_Name__c=:UserHelper.JOB_REP limit 3];
        // select a couple of inactive to check this case
        User[] inactiveUsers = [Select Id, Name,Sales_Org__c from User where UserRoleId != null and IsActive=false and Job_Name__c=:UserHelper.JOB_REP limit 2];
        
        System.debug('testDedicatedReps1 payUser 0='+payUsers[0].Id+' name='+payUsers[0].Name);
        System.debug('testDedicatedReps1 payUser 1='+payUsers[1].Id+' name='+payUsers[1].Name);
        System.debug('testDedicatedReps1 payUser 2='+payUsers[2].Id+' name='+payUsers[2].Name);
        
        Lead lead1a = new Lead(LastName='Test Lead1a', OwnerId=payUsers[2].Id, LeadSource='New1', Company='Test Company1');
        Lead lead1b = new Lead(LastName='Test Lead1b', OwnerId=payUsers[2].Id, LeadSource='New2', Company='Test Company2');
        Lead lead2a = new Lead(LastName='Test Lead2a', OwnerId=payUsers[2].Id, LeadSource='New3', Company='Test Company3');
        Lead lead3 = new Lead(LastName='Test Lead3', OwnerId=payUsers[2].Id, LeadSource='New4', Company='Test Company4');
        Lead lead4 = new Lead(LastName='Test Lead4', OwnerId=payUsers[2].Id, LeadSource='New5', Company='Test Company5');
        Lead lead5 = new Lead(LastName='Test Lead5', OwnerId=payUsers[2].Id, LeadSource='New6', Company='Test Company6');
        Lead lead6 = new Lead(LastName='Test Lead6', OwnerId=payUsers[2].Id, LeadSource='New7', Company='Test Company7');
        Lead lead7 = new Lead(LastName='Test Lead7', OwnerId=payUsers[2].Id, LeadSource='New8', Company='Test Company8');
        Lead lead8 = new Lead(LastName='Test Lead8', OwnerId=payUsers[2].Id, Hold_Out__c=true, Hold_Out_Expiration__c=Date.today().addDays(30), LeadSource='New9', Company='Test Company9');
        Lead lead9 = new Lead(LastName='Test Lead9', OwnerId=payUsers[2].Id, Hold_Out__c=true,  Hold_Out_Expiration__c=Date.today().addDays(30), LeadSource='New10', Company='Test Company10');
        Lead lead10 = new Lead(LastName='Test Lead10', OwnerId=payUsers[2].Id, Hold_Out__c=true, Hold_Out_Expiration__c=Date.today().addDays(30), Hold_Out_Reason__c=ReferralAccountChkAcctOwner.HOLD_OUT_SA, LeadSource='New11', Company='Test Company11');
        Lead lead11 = new Lead(LastName='Test Lead11', OwnerId=payUsers[2].Id, Hold_Out__c=true, Hold_Out_Expiration__c=Date.today().addDays(30), Hold_Out_Reason__c=ReferralAccountChkAcctOwner.HOLD_OUT_CENTRIC, LeadSource='New12', Company='Test Company12');
        Lead[] leads = new Lead[]{lead1a,lead1b,lead2a,lead3,lead4,lead5,lead6,lead7,lead8,lead9,lead10,lead11};
            ZipCheckOwner.SKIP_TRIGGERS=true;
        insert leads;
        
        id refAcctRT5 = RecordTypeHelper.getRecordType('Sales Channel Referral Account Record Type','Referral_Account__c').getRecordTypeId();  
        
        // create a couple of parent referral accounts.
        Referral_Account__c refAcctParent1 = new Referral_Account__c(Name='Test Parent1');
        Referral_Account__c refAcctParent2 = new Referral_Account__c(Name='Test Parent2');
        Referral_Account__c[] refAcctParents = new Referral_Account__c[]{refAcctParent1,refAcctParent2};
            TriggerMethods.clearVariables();
        insert refAcctParents;
        
        System.debug('testDedicatedReps1 refAcctParent1 dedicated='+refAcctParent1.DedicatedRep__c);
        System.debug('testDedicatedReps1 refAcctParent2 dedicated='+refAcctParent2.DedicatedRep__c);
        
        Referral_Account__c refAcctChild1a = new Referral_Account__c(Name='Child a of Parent1', Parent_Referral_Account__c=refAcctParent1.Id);
        Referral_Account__c refAcctChild1b = new Referral_Account__c(Name='Child b of Parent1', Parent_Referral_Account__c=refAcctParent1.Id);
        Referral_Account__c refAcctChild2a = new Referral_Account__c(Name='Child a of Parent2', Parent_Referral_Account__c=refAcctParent2.Id);
        Referral_Account__c refAcct3 = new Referral_Account__c(Name='Ref Acct 3');
        // there's a field validation rule looking for the record type for a strategic/national account.
        Referral_Account__c refAcct4 = new Referral_Account__c(Name='Ref Acct 4', RecordTypeId=refAcctRT5);
        Referral_Account__c refAcct5 = new Referral_Account__c(Name='Ref Acct 5');
        // this should not prompt an ownership change since the owner is inactive
        Referral_Account__c refAcct6 = new Referral_Account__c(Name='Ref Acct 6');
        // no dedicated rep so no change - set the flag so it falls into the batch.
        Referral_Account__c refAcct7 = new Referral_Account__c(Name='Ref Acct 7', DedicatedRepChanged__c=true);
        Referral_Account__c[] refAccts = new Referral_Account__c[]{refAcctChild1a,refAcctChild1b,refAcctChild2a,refAcct3,refAcct4,refAcct5,refAcct6,refAcct7};
            TriggerMethods.clearVariables();
        insert refAccts;
        

        Referral_Account_Team__c ratForRA1= new Referral_Account_Team__c(Referral_Account__c = refAcct3.Id,Team_Member_Name__c=payUsers[0].Id);
        Referral_Account_Team__c ratForRA2= new Referral_Account_Team__c(Referral_Account__c = refAcct4.Id,Team_Member_Name__c=payUsers[1].Id);
        Referral_Account_Team__c ratForRA3= new Referral_Account_Team__c(Referral_Account__c = refAcct5.Id,Team_Member_Name__c=payUsers[2].Id);
        Referral_Account_Team__c ratForRA4= new Referral_Account_Team__c(Referral_Account__c = refAcct6.Id,Team_Member_Name__c=inactiveUsers[0].Id);
        Referral_Account_Team__c[] rats = new Referral_Account_Team__c[]{ratForRA1,ratForRA2,ratForRA3,ratForRA4};
            insert rats;
        //doing this to get 'Account_Owner__c' formula field from rats
        //Formula.recalculateFormulas(rats);
        
        // make sure the flag is set on the referral accounts we want to be in the batch.
        System.assertEquals(5, [Select count() from Referral_Account__c where DedicatedRepChanged__c=true]);
        
        Referral_Contact__c refCtctChild1a = new Referral_Contact__c(Referral_Account__c=refAcctChild1a.Id, Name='Test Ctct1a');
        Referral_Contact__c refCtctChild1b = new Referral_Contact__c(Referral_Account__c=refAcctChild1b.Id, Name='Test Ctct1b');
        Referral_Contact__c refCtctChild2a = new Referral_Contact__c(Referral_Account__c=refAcctChild2a.Id, Name='Test Ctct2a');
        Referral_Contact__c refCtct3 = new Referral_Contact__c(Referral_Account__c=refAcct3.Id, Name='Test Ctct3');
        Referral_Contact__c refCtct4 = new Referral_Contact__c(Referral_Account__c=refAcct4.Id, Name='Test Ctct4');
        Referral_Contact__c refCtct5 = new Referral_Contact__c(Referral_Account__c=refAcct5.Id, Name='Test Ctct5');
        Referral_Contact__c refCtct6 = new Referral_Contact__c(Referral_Account__c=refAcct6.Id, Name='Test Ctct6');
        Referral_Contact__c refCtct7 = new Referral_Contact__c(Referral_Account__c=refAcct7.Id, Name='Test Ctct7');
        Referral_Contact__c[] refCtcts = new Referral_Contact__c[]{refCtctChild1a,refCtctChild1b,refCtctChild2a,refCtct3,refCtct4,refCtct5,refCtct6,refCtct7};
            TriggerMethods.clearVariables();
        insert refCtcts;
        
        lead11.Referral_Contact__c = refCtctChild1a.Id;
        lead10.Referral_National_Account__c = refAcct4.Id;
        
        // todo - once the field change is running in the trigger we want to disable it here so it's picked up by the batch
        ReferralAccountChkAcctOwner.SKIP_RFRL_OWNERSHIP_TRIGGER = true;
        TriggerMethods.clearVariables();
        update leads;
        
        Test.startTest();
        
        ReferralAccountChkAcctBatch racab = new ReferralAccountChkAcctBatch(); 
        racab.mode=ReferralAccountChkAcctBatch.MODE_LEAD;
        database.executeBatch(racab, 30);
        
        Test.stopTest();
        
        Map<Id,Lead> leadMap = getLeadMap(leads);
        verifyLeadFromRAT('lead11', leadMap.get(lead11.Id), payUsers[0], ratForRA2, true, ReferralAccountChkAcctOwner.HOLD_OUT_CENTRIC, Date.today().addDays(30));
        verifyLeadFromRAT('lead1a', leadMap.get(lead1a.Id), payUsers[0], ratForRA3, true, ReferralAccountChkAcctOwner.HOLD_OUT_CENTRIC, Date.today().addDays(30));
        verifyLeadFromRAT('lead10', leadMap.get(lead10.Id), payUsers[1], ratForRA1, true, ReferralAccountChkAcctOwner.HOLD_OUT_SA, Date.today().addDays(30));
        verifyLeadFromRAT('lead6', leadMap.get(lead6.Id), payUsers[2], ratForRA4, false, null, null);
        verifyLeadFromRAT('lead7', leadMap.get(lead7.Id), payUsers[2], null, false, null, null);
        
        System.assertEquals(0,[select count() from Referral_Account__c where DedicatedRepChanged__c=true]);
        
    } // testleads
    
    static testMethod void testScheduler() {
        TestHelper.testScheduler('TestReferralAccountChkAcctBatch', new ReferralAccountChkAcctBatch());
    } // testScheduler
    
} // class ReferralAccountChkAcctOwnerTest