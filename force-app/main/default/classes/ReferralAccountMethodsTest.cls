/* Test Method for ReferalAccountMethods 
*
*History
*----------------
* 
*   01/07/2015 Jacob Hinds      Created. Added in test for Sensitivity
07/25/2016 Dan Carmen       Change to make code more dynamic.
11/02/2018 Dan Carmen       Add new fields to custom setting
12/04/2018 Cindy Freeman    Add LatestCampaign to test
06/30/2021 Dan Carmen         Clear email verification when email changes, format phone numbers
08/25/2021 Dan Carmen         Replace Referral Contact Outcode process builder, Referral Contact - Referral Type process builder
03/18/2022 Dan Carmen         Fix setting primary referral type
08/14/2023 Tej Pothuri         Improved code coverage
12/04/2023 Susmitha Somavarapu Commented out outcome field, outcome date field for field removal for cpa profiling work APR0160191.

*/
@isTest
public class ReferralAccountMethodsTest {
    
    @testSetup
    public static void setupTestData() {
        TriggerMethodsTest.createTriggerSetting('ReferralContactBefore', true, false, false, false,new String[]{'ReferralAccountMethods'});
        TriggerMethodsTest.saveSetupClasses();
        
    } // setupTestData
    
    public static void setupSensitivityCustomSetting() {
        ProductSensitivityFields__c[] psfs = new ProductSensitivityFields__c[]{};
            psfs.add(new ProductSensitivityFields__c(Name='Sensitivity_401_k__c', FieldName__c='Sensitivity_401_k__c', Label__c='401k', OnAccount__c=true, OnContact__c=true, RefAcct__c=true, RefCtct__c=true, APS__c=false, AccountRollupField__c='HasSensitivity401k__c'));
        psfs.add(new ProductSensitivityFields__c(Name='Sensitivity_Credit_Card_Processing__c', FieldName__c='Sensitivity_Credit_Card_Processing__c', Label__c='CC Processing', OnAccount__c=true, OnContact__c=true, RefAcct__c=true, RefCtct__c=true, APS__c=false, AccountRollupField__c=''));
        psfs.add(new ProductSensitivityFields__c(Name='Sensitivity_FSA__c', FieldName__c='Sensitivity_FSA__c', Label__c='FSA', OnAccount__c=true, OnContact__c=true, RefAcct__c=true, RefCtct__c=true, APS__c=false, AccountRollupField__c='HasSensitivityFSA__c'));
        psfs.add(new ProductSensitivityFields__c(Name='Sensitivity_Health_Ins__c', FieldName__c='Sensitivity_Health_Ins__c', Label__c='Health Ins', OnAccount__c=true, OnContact__c=true, RefAcct__c=true, RefCtct__c=true, APS__c=false, AccountRollupField__c='HasSensitivityHNBF__c'));
        psfs.add(new ProductSensitivityFields__c(Name='Sensitivity_PAO__c', FieldName__c='Sensitivity_PAO__c', Label__c='PAO', OnAccount__c=true, OnContact__c=true, RefAcct__c=true, RefCtct__c=true, APS__c=false, AccountRollupField__c=''));
        psfs.add(new ProductSensitivityFields__c(Name='Sensitivity_Sales_Tax__c', FieldName__c='Sensitivity_Sales_Tax__c', Label__c='Sales Tax', OnAccount__c=true, OnContact__c=true, RefAcct__c=true, RefCtct__c=true, APS__c=false, AccountRollupField__c=''));
        psfs.add(new ProductSensitivityFields__c(Name='Sensitivity_Wrks_Comp__c', FieldName__c='Sensitivity_Wrks_Comp__c', Label__c='Wrks Comp', OnAccount__c=true, OnContact__c=true, RefAcct__c=true, RefCtct__c=true, APS__c=false, AccountRollupField__c='HasSensitivityHNBF__c'));
        psfs.add(new ProductSensitivityFields__c(Name='Oasis_401k_Sensitivity__c', FieldName__c='Oasis_401k_Sensitivity__c', Label__c='Oasis 401k', OnAccount__c=false, OnContact__c=false, RefAcct__c=false, RefCtct__c=false, APS__c=true, AccountRollupField__c=''));
        insert psfs;
    }
    
    //method that creates a generic test referral account   
    static Referral_Account__c createTestRefAcct(id refAcctRT1){
        return new Referral_Account__c(name = 'RefAcctCreate'
                                       ,recordtypeid = refAcctRT1
                                       ,Referral_Source_Business_Type__c = ReferralScoreMethodsTest.REF_SOURCE_FA
                                       ,Street_Address_1__c = '911 Panorama Trail South'
                                       ,City__c = 'Rochester'
                                       ,State_Province__c = 'NY'
                                       ,Zip_Postal_Code__c = '14586');
    }    
    //method that creates a generic test referral contact  
    static Referral_Contact__c createTestRefCntct(id refCntctRT1,id refAcct1){
        return new Referral_Contact__c(name = 'First Last'
                                       ,recordtypeid = refCntctRT1
                                       ,Referral_Account__c = refAcct1
                                       ,Mailing_Street__c = '123'
                                       ,Mailing_City__c = 'Rochester'
                                       ,Mailing_State__c = 'NY'
                                       ,Mailing_Postal_Code__c = '14514'
                                       ,Mailing_Country__c = 'US');
    }
    //method that creates a referral account contact role 
    static Referral_Contact_Role__c createRefCntctRole (id refCntct1, id RefAcct1){
        return new Referral_Contact_Role__c (Referral_Contact__c = refCntct1
                                             ,Referral_Account__c = refacct1
                                             ,Role__c = 'Financial Advisor');
    }
    
    static testMethod void testSensitivity(){
        setupSensitivityCustomSetting();
        ReferralAccountMethods.CHECK_ACCOUNT_SENSITIVITY_LIST = true;
        
        id refAcctRT = RecordTypeHelper.getRecordType('Core Referral Source Record Type','Referral_Account__c').getRecordTypeId();
        id refCntctRT = RecordTypeHelper.getRecordType('Core Referral Record Type','Referral_Contact__c').getRecordTypeId();
        
        Referral_Account__c parentRefAcct = ReferralAccountMethodsTest.createTestRefAcct(refAcctRT);
        insert parentRefAcct;
        Referral_Account__c childRefAcct = ReferralAccountMethodsTest.createTestRefAcct(refAcctRT);
        childRefAcct.Parent_Referral_Account__c = parentRefAcct.Id;
        insert childRefAcct;
        
        Referral_Contact__c refCntct1 = ReferralAccountMethodsTest.createTestRefCntct(refCntctRT, childRefAcct.id);
        Referral_Contact__c refCntct2 = ReferralAccountMethodsTest.createTestRefCntct(refCntctRT, childRefAcct.id);
        List<Referral_Contact__c> cntcts = new List<Referral_Contact__c>();
        cntcts.add(refCntct1);
        cntcts.add(refCntct2);
        insert cntcts;
        
        Test.startTest();
        
        parentRefAcct.Sensitivity_401_k__c = true;
        parentRefAcct.Sensitivity_Credit_Card_Processing__c = true;
        parentRefAcct.Sensitivity_FSA__c = true;
        parentRefAcct.Sensitivity_Health_Ins__c = true;
        parentRefAcct.Sensitivity_PAO__c = true;
        parentRefAcct.Sensitivity_Sales_Tax__c = true;
        parentRefAcct.Sensitivity_Wrks_Comp__c = true;
        ReferralAccountMethods.SENSITIVITY_UPDATE_IN_PROGRESS = false;
        update parentRefAcct;
        
        Referral_Account__c updatedAccount = [SELECT Id,Sensitivity_401_k__c, Sensitivity_Credit_Card_Processing__c
                                              ,Sensitivity_FSA__c, Sensitivity_Health_Ins__c, Sensitivity_PAO__c, Sensitivity_Sales_Tax__c
                                              ,Sensitivity_Wrks_Comp__c FROM Referral_Account__c WHERE Parent_Referral_Account__c = :parentRefAcct.Id LIMIT 1]; 
        System.debug('testSensitivity updatedAccount='+updatedAccount);
        
        system.assertEquals(updatedAccount.Sensitivity_401_k__c,true);
        system.assertEquals(updatedAccount.Sensitivity_Credit_Card_Processing__c,true);
        system.assertEquals(updatedAccount.Sensitivity_FSA__c,true);
        system.assertEquals(updatedAccount.Sensitivity_Health_Ins__c,true);
        system.assertEquals(updatedAccount.Sensitivity_PAO__c,true);
        system.assertEquals(updatedAccount.Sensitivity_Sales_Tax__c,true);
        system.assertEquals(updatedAccount.Sensitivity_Wrks_Comp__c,true);
        
        List<Referral_Contact__c> updatedCntcts = [SELECT Id,Sensitivity_401_k__c, Sensitivity_Credit_Card_Processing__c
                                                   ,Sensitivity_FSA__c, Sensitivity_Health_Ins__c, Sensitivity_PAO__c, Sensitivity_Sales_Tax__c
                                                   ,Sensitivity_Wrks_Comp__c FROM Referral_Contact__c WHERE Referral_Account__c = :childRefAcct.Id];
        
        for(Referral_Contact__c ct:updatedCntcts){
            System.debug('testSensitivity ct='+ct);
            system.assertEquals(ct.Sensitivity_401_k__c,true);
            system.assertEquals(ct.Sensitivity_Credit_Card_Processing__c,true);
            system.assertEquals(ct.Sensitivity_FSA__c,true);
            system.assertEquals(ct.Sensitivity_Health_Ins__c,true);
            system.assertEquals(ct.Sensitivity_PAO__c,true);
            system.assertEquals(ct.Sensitivity_Sales_Tax__c,true);
            system.assertEquals(ct.Sensitivity_Wrks_Comp__c,true);
        }
        
        Test.stopTest();
        
    } // testSensitivity
    
    static testMethod void testLoadFlds() {
        ReferralAccountMethods.CHECK_ACCOUNT_SENSITIVITY_LIST = true;
        // so the trigger fires.
        User runningUser = UserHelper.getRunningUser();
        ProcessNameMap__c pnm = UserHelperTest.setupProcessName(UserHelper.PREFIX_LL,runningUser.Name);
        
        Account payxAcct = new Account(Name=UserHelper.PAYCHEX_COMP);
        insert payxAcct;
        
        User[] users = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where IsActive=true and HR_Person_Id__c != null and Sales_Org__c=:UserHelper.SO_CORE limit 4];
        Contact ctct1 = new Contact(AccountId=payxAcct.Id, FirstName=users[0].FirstName, LastName=users[0].LastName, Email=users[0].Email, HR_Person_Id__c=users[0].HR_Person_Id__c, User_Lookup__c=users[0].Id);
        Contact ctct2 = new Contact(AccountId=payxAcct.Id, FirstName=users[1].FirstName, LastName=users[1].LastName, Email=users[1].Email, HR_Person_Id__c=users[1].HR_Person_Id__c, User_Lookup__c=users[1].Id);
        Contact ctct3 = new Contact(AccountId=payxAcct.Id, FirstName=users[2].FirstName, LastName=users[2].LastName, Email=users[2].Email, HR_Person_Id__c=users[2].HR_Person_Id__c, User_Lookup__c=users[2].Id);
        Contact ctct4 = new Contact(AccountId=payxAcct.Id, FirstName=users[3].FirstName, LastName=users[3].LastName, Email=users[3].Email, HR_Person_Id__c=users[3].HR_Person_Id__c, User_Lookup__c=users[3].Id);
        Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3,ctct4};
            insert ctcts;
        
        Referral_Account__c refAcct1 = new Referral_Account__c(Name='Test Acct 1', LoadAccountOwner__c=ctct1.Email, LoadBankCentricRep__c=ctct2.Email
                                                               ,LoadCPARelationshipMgr__c=users[2].Id, LoadDedicatedRep__c=ctct4.Email);
        Referral_Account__c refAcct2 = new Referral_Account__c(Name='Test Acct 2', LoadAccountOwner__c=ctct1.Email, LoadBankCentricRep__c=ctct2.Email
                                                               ,LoadCPARelationshipMgr__c=ctct3.Email, LoadDedicatedRep__c=ctct4.Email);
        Referral_Account__c[] refAccts = new Referral_Account__c[]{refAcct1,refAcct2};
            insert refAccts;
        
        refAcct1 = [Select Id, Name
                    ,LoadAccountOwner__c, LoadAccountOwnerPrev__c, OwnerId
                    ,LoadBankCentricRep__c, LoadBankCentricRepPrev__c, Bank_Centric_Rep__c
                    ,LoadCPARelationshipMgr__c, LoadCPARelationshipMgrPrev__c, CPA_Relationship_Manager__c
                    ,LoadDedicatedRep__c, LoadDedicatedRepPrev__c, Dedicated_Rep__c
                    From Referral_Account__c where Id=:refAcct1.Id];
        
        System.assertEquals(null, refAcct1.LoadAccountOwner__c);
        System.assertEquals(ctct1.Email, refAcct1.LoadAccountOwnerPrev__c);
        System.assertEquals(ctct1.User_Lookup__c, refAcct1.OwnerId);
        
        System.assertEquals(null, refAcct1.LoadBankCentricRep__c);
        System.assertEquals(ctct2.Email, refAcct1.LoadBankCentricRepPrev__c);
        System.assertEquals(ctct2.User_Lookup__c, refAcct1.Bank_Centric_Rep__c);
        
        System.assertEquals(null, refAcct1.LoadCPARelationshipMgr__c);
        System.assertEquals(users[2].Id, refAcct1.LoadCPARelationshipMgrPrev__c);
        System.assertEquals(ctct3.User_Lookup__c, refAcct1.CPA_Relationship_Manager__c);
        
        System.assertEquals(null, refAcct1.LoadDedicatedRep__c);
        System.assertEquals(ctct4.Email, refAcct1.LoadDedicatedRepPrev__c);
        System.assertEquals(ctct4.Id, refAcct1.Dedicated_Rep__c);
        
        ReferralAccountMethods.resetVariables();
        refAcct1.LoadDedicatedRep__c = 'bademail@thisisatest.com';
        update refAcct1;
        
        refAcct1 = [Select Id, Name
                    ,LoadAccountOwner__c, LoadAccountOwnerPrev__c, OwnerId
                    ,LoadBankCentricRep__c, LoadBankCentricRepPrev__c, Bank_Centric_Rep__c
                    ,LoadCPARelationshipMgr__c, LoadCPARelationshipMgrPrev__c, CPA_Relationship_Manager__c
                    ,LoadDedicatedRep__c, LoadDedicatedRepPrev__c, Dedicated_Rep__c
                    From Referral_Account__c where Id=:refAcct1.Id];
        
        System.assertEquals('bademail@thisisatest.com', refAcct1.LoadDedicatedRep__c);
        System.assertEquals(ctct4.Email, refAcct1.LoadDedicatedRepPrev__c);
        System.assertEquals(ctct4.Id, refAcct1.Dedicated_Rep__c);
        
        refAcct2 = [Select Id, Name
                    ,LoadAccountOwner__c, LoadAccountOwnerPrev__c, OwnerId
                    ,LoadBankCentricRep__c, LoadBankCentricRepPrev__c, Bank_Centric_Rep__c
                    ,LoadCPARelationshipMgr__c, LoadCPARelationshipMgrPrev__c, CPA_Relationship_Manager__c
                    ,LoadDedicatedRep__c, LoadDedicatedRepPrev__c, Dedicated_Rep__c
                    From Referral_Account__c where Id=:refAcct2.Id];
        
        System.assertEquals(null, refAcct2.LoadAccountOwner__c);
        System.assertEquals(ctct1.Email, refAcct2.LoadAccountOwnerPrev__c);
        System.assertEquals(ctct1.User_Lookup__c, refAcct2.OwnerId);
        
        System.assertEquals(null, refAcct2.LoadBankCentricRep__c);
        System.assertEquals(ctct2.Email, refAcct2.LoadBankCentricRepPrev__c);
        System.assertEquals(ctct2.User_Lookup__c, refAcct2.Bank_Centric_Rep__c);
        
        System.assertEquals(null, refAcct2.LoadCPARelationshipMgr__c);
        System.assertEquals(ctct3.Email, refAcct2.LoadCPARelationshipMgrPrev__c);
        System.assertEquals(ctct3.User_Lookup__c, refAcct2.CPA_Relationship_Manager__c);
        
        System.assertEquals(null, refAcct2.LoadDedicatedRep__c);
        System.assertEquals(ctct4.Email, refAcct2.LoadDedicatedRepPrev__c);
        System.assertEquals(ctct4.Id, refAcct2.Dedicated_Rep__c);
        
        Campaign cmp = new Campaign(Name = 'Paychex Test Campaign', Status='In Progress',StartDate = System.TODAY(), IsActive=true);
        insert cmp;
        Referral_Contact__c refCtct = new Referral_Contact__c(Name='Test RC', LatestCampaign__c=cmp.Id,Referral_Account__c = refAcct1.Id);
        insert refCtct;
        refCtct = [Select Id, Name, LoadCampaign__c,LoadCampaignPrev__c,LatestCampaign__c from Referral_Contact__c where id = :refCtct.Id];
        System.assertEquals(refCtct.LoadCampaignPrev__c,cmp.Id);
        System.assertEquals(refCtct.LatestCampaign__c, cmp.Id);
        System.assertEquals(refCtct.LoadCampaign__c,null);      
        
    } // testLoadFlds
    
    static testMethod void testPhoneEmail() {
        ReferralAccountMethods.FORMAT_PHONE=true;
        Referral_Account__c refAcct = new Referral_Account__c(Name='Ref Acct');
        ReferralAccountMethods.SKIP_TRIGGERS=true;
        insert refAcct;
        
        Referral_Contact__c refCtct1 = new Referral_Contact__c(Name='Contact One', Referral_Account__c=refAcct.Id, Phone__c='5551234567', Mobile_Phone__c='5552345678'
                                                               ,Email__c='one@test.com', Email_Verification__c='Bad One', Email_Verification_Date__c=Date.today());
        ReferralAccountMethods.SKIP_TRIGGERS=false;
        insert refCtct1;
        
        refCtct1 = [Select Id, Name, Phone__c, Mobile_Phone__c, Email__c, Email_Verification__c, Email_Verification_Date__c from Referral_Contact__c where Id=:refCtct1.Id];
        System.assertEquals('(555) 123-4567', refCtct1.Phone__c);
        System.assertEquals('(555) 234-5678', refCtct1.Mobile_Phone__c);
        System.assertNotEquals(null,refCtct1.Email_Verification__c);
        System.assertNotEquals(null,refCtct1.Email_Verification_Date__c);
        
        refCtct1.Email__c = 'two@test.com';
    //    refCtct1.Outcome__c='Outcome';
        ReferralAccountMethods.SKIP_TRIGGERS=false;
        update refCtct1;
        
        refCtct1 = [Select Id, Name, Phone__c, Mobile_Phone__c, Email__c, Email_Verification__c, Email_Verification_Date__c 
                   // ,Outcome__c 
                   // ,Outcome_Date__c
                    from Referral_Contact__c where Id=:refCtct1.Id];
        System.assertEquals('(555) 123-4567', refCtct1.Phone__c);
        System.assertEquals('(555) 234-5678', refCtct1.Mobile_Phone__c);
        System.assertEquals(null,refCtct1.Email_Verification__c);
        System.assertEquals(null,refCtct1.Email_Verification_Date__c);
     //   System.assertEquals(Date.today(), refCtct1.Outcome_Date__c);
        
    } // testPhoneEmail
    
    static testMethod void testCPAStatusUpdate() {
        Profile prof = [SELECT Id FROM Profile where name='CPA Customer Community Login User Clone' LIMIT 1];
        Account acc = new Account();
        acc.Name = 'Peo test';
        insert acc;
        Referral_Account__c refAcct = new Referral_Account__c(Name='Ref Acct');
        //ReferralAccountMethods.SKIP_TRIGGERS=true;
        insert refAcct;
        Contact ctct = new Contact(AccountId=acc.id,
                                   FirstName = 'test',
                                   LastName = 'user',
                                   Email='testuser@tested.com'); 
        insert ctct;
        Referral_Contact__c refCtct = new Referral_Contact__c(Name='Test RC', CPA_Program_status__c = 'Invited',Referral_Account__c = refAcct.Id, Contact__c = ctct.Id);
        insert refCtct;
        ctct.Mirror_Ref_Ctct__c = refCtct.Id;
        Update ctct;
        User testUser = new User(
            UserName = 'testuser@tested.com',
            FirstName = 'testFirstname',
            LastName ='testLastname',
            ContactId = ctct.id,
            Alias = 'alias',
            email = 'testuser@tested.com',
            ProfileId = prof.Id,
            EmailEncodingKey = 'UTF-8',
            CommunityNickname = 'nickName',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Sales_Org__c = 'PAS'
        );
        insert testUser;
        List<Id> inactivUsers = new List<Id>();
        inactivUsers.add(testUser.Id);
        ReferralAccountMethods.deActivateCPAUser(inactivUsers);
        refCtct.CPA_Program_status__c = 'Enrolled';
        refCtct.End_Date__c = System.today();
        Update refCtct;
        refCtct.CPA_Program_status__c = 'Unenrolled/no longer in Program';
        Update refCtct;
        Referral_Contact__c refContFinal = [Select id, CPA_Program_status__c from Referral_Contact__c where id=:refCtct.Id];
        System.debug('refContFinal:'+refContFinal);
        Referral_Account__c refAcctFinal = [Select id, CPA_Program_Status__c from Referral_Account__c where id=:refAcct.Id];
        System.debug('refAcctFinal:'+refAcctFinal);
        System.assertEquals('Unenrolled/no longer in Program', refContFinal.CPA_Program_status__c);
        System.assertEquals('No Longer In Program', refAcctFinal.CPA_Program_Status__c);
    }
    
    public static testMethod void testEndPortalUsers(){
        List<Id> lstContId = new List<Id>();
        List<Referral_Contact__c> lstRefCont = new List<Referral_Contact__c>();
        List<Referral_Account__c> lstRefAcc = new List<Referral_Account__c>();
        Account acc = new Account();
        acc.Name = 'Peo test';
        insert acc; 
        Referral_Account__c refAcct = new Referral_Account__c(Name='Ref Acct', CheckSensitivityList__c = true);
        //ReferralAccountMethods.SKIP_TRIGGERS=true;
        insert refAcct;
        Contact ctct = new Contact(AccountId=acc.id,
                                   FirstName = 'test',
                                   LastName = 'user',
                                   Email='testuser@tested.com');  
        insert ctct;
        Referral_Contact__c refCtct = new Referral_Contact__c(Name='Test RC',LoadNotifyRepPrev__c = 'HOT', CPA_Program_status__c = 'Invited',Referral_Account__c = refAcct.Id, Contact__c = ctct.Id);
        insert refCtct;  
        Referral_Contact__c refCtctWarm = new Referral_Contact__c(Name='Test RC',LoadNotifyRepPrev__c = 'Warm', CPA_Program_status__c = 'Invited',Referral_Account__c = refAcct.Id, Contact__c = ctct.Id);
        insert refCtctWarm;  
      //  Referral_Account__c refAcctNew = new Referral_Account__c(Name='Ref Acct New');
      //  insert refAcctNew;
        lstRefAcc.add(refAcct); 
        lstContId.add(ctct.Id);
        lstRefCont.add(refCtct);
        lstRefCont.add(refCtctWarm);
        ReferralAccountMethods.endPortalUsers(lstContId);
        ReferralAccountMethods.handleChatterMsg(lstRefCont);
        ReferralAccountMethods.handleChatterMsg(lstRefAcc);
        ReferralAccountMethods.checkCtctSensitivityList();
        ReferralAccountMethods.getSensitivityFldsForQuery();
        ReferralAccountMethods.checkBeforeActions(refAcct,refAcct);
    }
    public static testMethod void testEndPortalUsers2(){
        List<Id> lstContId = new List<Id>();
        List<Referral_Contact__c> lstRefCont = new List<Referral_Contact__c>();
        List<Referral_Account__c> lstRefAcc = new List<Referral_Account__c>();
        Account acc = new Account();
        acc.Name = 'Peo test';
        insert acc;
        Referral_Account__c refAcct = new Referral_Account__c(Name='Ref Acct', CheckSensitivityList__c = true);
        //ReferralAccountMethods.SKIP_TRIGGERS=true;
        insert refAcct;
        Contact ctct = new Contact(AccountId=acc.id,
                                   FirstName = 'test',
                                   LastName = 'user',
                                   Email='testuser@tested.com'); 
        insert ctct;
        Referral_Contact__c refCtctWarm = new Referral_Contact__c(Name='Test RC',
                                                                  LoadNotifyRepPrev__c = 'Warm',
                                                                  LoadCampaign__c = 'test',
                                                                  LoadNotifyRep__c = 'test',
                                                                  LoadLeadSource__c = 'test',
                                                                  LoadReferralType__c = 'test',
                                                                  CPA_Program_status__c = 'Invited',
                                                                  Referral_Account__c = refAcct.Id,
                                                                  Contact__c = ctct.Id);
        insert refCtctWarm;  
        lstRefCont.add(refCtctWarm);
        ReferralAccountMethods.handleChatterMsg(lstRefCont);
        ReferralAccountMethods.checkEmployeeLoadFields(refCtctWarm,refCtctWarm,true);
        
    }
} // class ReferralAccountMethodsTest