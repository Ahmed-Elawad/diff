/* Test Class for AddToCadence component and controller
* History
 * -------
   10/10/2019 Jake Hinds        Created
   04/27/2020 Dan Carmen        Add Target List to the form
   10/13/2021 Dan Carmen        Add a limit for how many active CARs you can add for yourself.
   06/20/2022 Dan Carmen        Update to Send to Partner routing

 */
@isTest
public class AddToCadenceControllerTest {
   public static String ACCT1_NAME='Test Account 1'; 
   public static String ACCT2_NAME='Test Account 2';
   public static String ACCT3_NAME='Test Account 3';
   public static String ACCT4_NAME='Test Account 4';
   public static String ACCT5_NAME='Test Account 5';
   public static String CAD_PROSP1='Prospect Activity';
   public static String CAD_PROSP0_20='Prospect No Act0_20';
   public static String CAD_PROSP21_100='Prospect No Act21_100';
   public static String CAD_CLT0_20='Client No Act0_20';
   public static String CAD_CLT21_100='Client No Act21_100';
   public static String CAD_RFRL_SRC='Client Rfrl Src';
   
   @testSetup
   static void setupData() {
      TriggerMethodsTest.createTriggerSetting('CadenceTrigger', true, true, false, false, new String[]{'CadenceHelper'});
      TriggerMethodsTest.saveSetupClasses();
      CadenceUpdateTest.setupTestCadence();
       
      TouchpointSetup__c tpSetup = TouchpointSetup__c.getOrgDefaults();
      tpSetup.ATCPOProspect__c = 'NSR/SDR Already Working';
      tpSetup.ATCPOLockout__c = 'NSR with Lockout';
      tpSetup.ATCTargetTypes__c = 'Prospect,Inbound Prospect';
      tpSetup.ATCOpenCarReason__c = 'Already In Cadence';
      tpSetup.ATCOpenOpp__c = 'Open Opportunity';
      tpSetup.NbrNSRCanReceive__c = 5;
      tpSetup.NbrRepCanHaveOpen__c = 5;
      tpSetup.NbrRepCanSend__c = 5;
      upsert tpSetup TouchpointSetup__c.Id;
       
      Map<String,Schema.RecordTypeInfo> rtMap = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
      Id rtId = rtMap.get(RecordTypeHelper.CORE_ACCOUNT).getRecordTypeId();
      Account acct1 = new Account(Name=ACCT1_NAME, RecordTypeId=rtId, Employees__c = 10, NumberOfEmployees=10);
      Account acct2 = new Account(Name=ACCT2_NAME, RecordTypeId=rtId, Employees__c = 30, NumberOfEmployees=30);
      Account acct3 = new Account(Name=ACCT3_NAME, RecordTypeId=rtId, Employees__c = 10, NumberOfEmployees=10, Bis_Id__c=77, First_Run_Date__c=Date.today().addDays(-91)
                                  ,Client_Status__c='A');
      Account acct4 = new Account(Name=ACCT4_NAME, RecordTypeId=rtId, Employees__c = 30, NumberOfEmployees=30, Bis_Id__c=78, First_Run_Date__c=Date.today().addDays(-91)
                                  ,Client_Status__c='A');
      Account acct5 = new Account(Name=ACCT5_NAME, RecordTypeId=rtId, Employees__c = 12, NumberOfEmployees=12);
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert new Account[]{acct1,acct2,acct3,acct4,acct5};
      System.assertEquals(2,[select count() from Account where CurrentClient__c=true]);
      System.assertEquals(3,[select count() from Account where NSS_WorkablePayroll__c=true]);
      System.assertEquals(2,[select count() from Account where NSS_WorkableHRS__c=true]);
       
          
      Contact ctct1 = new Contact(FirstName='Test',LastName='Contact1',AccountId=acct1.Id);
      Contact ctct2 = new Contact(FirstName='Test',LastName='Contact2',AccountId=acct2.Id);
      Contact ctct3 = new Contact(FirstName='Test',LastName='Contact3',AccountId=acct3.Id);
      Contact ctct4 = new Contact(FirstName='Test',LastName='Contact4',AccountId=acct4.Id);
      Contact ctct5 = new Contact(FirstName='Test',LastName='Contact5',AccountId=acct5.Id);
      insert new Contact[]{ctct1,ctct2,ctct3,ctct4,ctct5};
          
      Group grp1 = new Group(Name='AddToCadence Test1', Type='Queue');
      Group grp2 = new Group(Name='AddToCadence Test2', Type='Queue');
      Group grp3 = new Group(Name='AddToCadence Test3', Type='Queue');
      Group grp4 = new Group(Name='AddToCadence Test4', Type='Queue');
      Group grp5 = new Group(Name='AddToCadence Test5', Type='Queue');
      Group grp6 = new Group(Name='AddToCadence Test6', Type='Queue');

      Group[] grps = new Group[]{grp1,grp2,grp3,grp4,grp5,grp6};
      insert grps;

      Assignment_Group_Name__c[] asgnGrps = new Assignment_Group_Name__c[]{};
      Assignment_Group_Queues__c[] asgnQueus = new Assignment_Group_Queues__c[]{};

      User runningUser = UserHelper.getRunningUser();
      System.runAs(runningUser) {
         QueueSObject[] qSObjs = new QueueSObject[]{};
         for (Group queue : grps) {
            qSObjs.add(new QueueSObject(QueueID = queue.id, SobjectType = 'Cadence_Assignment_Record__c'));
            qSObjs.add(new QueueSObject(QueueID = queue.id, SobjectType = 'Cadence_Touchpoint__c'));
            Assignment_Group_Name__c agn = new Assignment_Group_Name__c(Name=queue.Name);
            asgnGrps.add(agn);
            asgnQueus.add(new Assignment_Group_Queues__c(Name=queue.Name, QueueId__c=queue.Id, Assignment_Group_Name__r=agn));
         }
         insert qSObjs;
      } // System.runAs(runningUser
       
      insert asgnGrps; 
      for (Assignment_Group_Queues__c agq : asgnQueus) {
         agq.Assignment_Group_Name__c = agq.Assignment_Group_Name__r.Id;
         agq.Assignment_Group_Name__r = null;
      }
      insert asgnQueus;
      System.assertEquals(grps.size(), [select count() from Assignment_Group_Queues__c]);

      Cadence__c cad1 = new Cadence__c(Name=CAD_PROSP1, Active__c=true, SendToPartner__c=true, Cadence_Type__c='Prospect', EmpsMin__c=null, EmpsMax__c=null
                                      , LastActivityDays__c=30, SendToPartnerQueue__c=grp1.Name,TargetType__c='Prospect', Priority__c=100, WorkablePayroll__c=true );
      Cadence__c cad2 = new Cadence__c(Name=CAD_PROSP0_20, Active__c=true, SendToPartner__c=true, Cadence_Type__c='Prospect', EmpsMin__c=0, EmpsMax__c=20
                                      , LastActivityDays__c=null, SendToPartnerQueue__c=grp2.Name,TargetType__c='Prospect', Priority__c=90, WorkablePayroll__c=true );
      Cadence__c cad3 = new Cadence__c(Name=CAD_PROSP21_100, Active__c=true, SendToPartner__c=true, Cadence_Type__c='', EmpsMin__c=21, EmpsMax__c=100
                                      , LastActivityDays__c=null, SendToPartnerQueue__c=grp3.Name,TargetType__c='Prospect', Priority__c=80, WorkablePayroll__c=true );
      Cadence__c cad4 = new Cadence__c(Name=CAD_CLT0_20, Active__c=true, SendToPartner__c=true, Cadence_Type__c='', EmpsMin__c=0, EmpsMax__c=20
                                      , LastActivityDays__c=null, SendToPartnerQueue__c=grp4.Name,TargetType__c='Client', Priority__c=70, WorkableHRS__c=true, WorkableCurrentClient__c=true );
      Cadence__c cad5 = new Cadence__c(Name=CAD_CLT21_100, Active__c=true, SendToPartner__c=true, Cadence_Type__c='', EmpsMin__c=21, EmpsMax__c=100
                                      , LastActivityDays__c=null, SendToPartnerQueue__c=grp5.Name,TargetType__c='Client', Priority__c=60, WorkableHRS__c=true );
      Cadence__c cad6 = new Cadence__c(Name=CAD_RFRL_SRC, Active__c=true, SendToPartner__c=true, Cadence_Type__c='', EmpsMin__c=21, EmpsMax__c=100
                                      , LastActivityDays__c=null, SendToPartnerQueue__c=grp6.Name,TargetType__c='Referral Source', Priority__c=50, WorkableHRS__c=false
                                      , ReferralSourceBusinessType2__c='Accounting Firm' );
      Cadence__c[] cads = new Cadence__c[]{cad1,cad2,cad3,cad4,cad5,cad6};
      insert cads;
       
      System.assertEquals(6,[Select count() from Cadence__c where SendToPartnerQueueId__c != null]);

      EmailTemplate et = [Select Id from EmailTemplate where TemplateType = 'Text' limit 1];
          
      Cadence_Step__c[] newSteps = new Cadence_Step__c[]{};
      for (Cadence__c cad : cads) {
         newSteps.add(new Cadence_Step__c(Name='Step 1', CadenceId__c = cad.Id, Touchpoint_Type__c = 'Email', Step_Number__c = 1, EmailTemplateIds__c = et.Id));
         newSteps.add(new Cadence_Step__c(Name='Step 2', CadenceId__c = cad.Id, Touchpoint_Type__c = 'Call', Step_Number__c = 2, Generate_Activity__c=true));    
      } // for (Cadence__c cad : cads
      insert newSteps;
    } // setupData
    
    public static void setCadenceType(String cadType) {
       Cadence__c[] cads = [Select Id, Name, Cadence_Type__c from Cadence__c where SendToPartner__c=true];
       for (Cadence__c cad : cads) {
          cad.Cadence_Type__c = cadType;
       }
       CadenceHelper.SKIP_TRIGGERS = true;
       update cads;
       CadenceHelper.SKIP_TRIGGERS = false;
    } // setCadenceType
    
    public static Account getTestAcct(String acctName) {
       Account acct = [Select Id, Name
                            ,(Select Id, FirstName, LastName, Name, AccountId from Contacts)
                        From Account
                       Where Name=:acctname];
       return acct;
    } // getTestAcct
    
    public static Cadence__c getCadence(String cadName) {
       Cadence__c cad = [Select Id, Name, Active__c, SendToPartner__c, Cadence_Type__c, EmpsMin__c, EmpsMax__c
                               ,LastActivityDays__c, SendToPartnerQueue__c,TargetType__c, Priority__c
                               ,WorkableHRS__c, WorkableCurrentClient__c, WorkablePayroll__c
                               ,IsClientCadence__c, IsProspectCadence__c, ReferralSourceCadence__c
                               ,ReferralSourceBusinessType2__c, SendToPartnerQueueId__c
                               ,(Select Id, Name, Touchpoint_Type__c,Step_Number__c from Cadence_Steps__r order by Step_Number__c )
                           From Cadence__c Where Name=:cadName];
       return cad;
    } // getCadence
    
    public static User[] getTestUsers() {
       User[] users = [SELECT Id,User_Cadence_Type__c FROM User WHERE isActive = true and Job_Name__c=:UserHelper.JOB_REP and Cadence_Opportunity_Type__c=null LIMIT 4];
       return users;
    } // getTestUsers
    
    static testMethod void testMisc() {
        AddToCadenceController atcc = new AddToCadenceController();
        TouchpointSetup__c tpSetup = TouchpointSetup__c.getOrgDefaults();
        
        System.assertEquals(tpSetup.NbrNSRCanReceive__c,atcc.nsrReceiveLimit);
        System.assertEquals(tpSetup.NbrRepCanSend__c,atcc.referToOtherLimit);

    } // testMisc
    
    static testMethod void testSuggestedUserLimit() {
        // get some NSRs
        User[] users = getTestUsers();
        User nsr1 = users[0];
        User nsr2 = users[1];
        Cadence__c cad = CadenceUpdateTest.getTestCadence();
        // create test leads
        Lead[] newLeads = new Lead[]{};
        for (Integer cnt=0; cnt<7; cnt++) {
           newLeads.add(new Lead(FirstName='Larry'+cnt, LastName='Lead'+cnt, Company='Larry Lead'+cnt));
        }
        TriggerMethods.SKIP_TRIGGERS=true;
        insert newLeads;
        // leads for rep2
        Lead ld1 = new Lead(FirstName='Tim1', LastName='Test1', Company='Tim Test1 Inc');
        Lead ld2 = new Lead(FirstName='Tim2', LastName='Test2', Company='Tim Test2 Inc');
        Lead ld3 = new Lead(FirstName='Tim2', LastName='Test2', Company='Tim Test2 Inc');
        insert new Lead[]{ld1,ld2,ld3};

        // assign to user so they have CARs
        Cadence_Assignment_Record__c[] newCars = new Cadence_Assignment_Record__c[]{};
        for (Lead ld : newLeads) {
           newCars.add(new Cadence_Assignment_Record__c(Name=ld.Company, OwnerId=nsr1.Id, Cadence_Owner__c=nsr1.Id, Cadence__c=cad.Id, CadenceObject__c=ld.Id
                                                        , SendToPartnerStatus__c=CAROwnershipQueueable.STATUS_QUEUE, Source__c=AddToCadenceController.CLASSNAME));
        }
        newCars.add(new Cadence_Assignment_Record__c(Name=ld1.Company, OwnerId=nsr2.Id, Cadence_Owner__c=nsr2.Id, Cadence__c=cad.Id, CadenceObject__c=ld1.Id
                                                     , SendToPartnerStatus__c=CAROwnershipQueueable.STATUS_QUEUE, Source__c=AddToCadenceController.CLASSNAME));
        newCars.add(new Cadence_Assignment_Record__c(Name=ld2.Company, OwnerId=nsr2.Id, Cadence_Owner__c=nsr2.Id, Cadence__c=cad.Id, CadenceObject__c=ld2.Id
                                                     , SendToPartnerStatus__c=CAROwnershipQueueable.STATUS_QUEUE, Source__c=AddToCadenceController.CLASSNAME));
        insert newCars;
        
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(ld3);
        AddToCadenceController atcc = new AddToCadenceController(stdCtrl);
        system.assertEquals(ld3.Id, atcc.recId);
        System.assertEquals(true,atcc.hasReferOptions);
        atcc.referTo=AddToCadenceController.REFER_ELSE;
        atcc.selectedCadence=String.valueOf(cad.Id);
        
        atcc.tempCar.Telemarketing_Rep__c=nsr1.Id;
        System.assertEquals(false,atcc.checkNsrLimit());

        atcc.tempCar.Telemarketing_Rep__c=nsr2.Id;
        System.assertEquals(true,atcc.checkNsrLimit());
        
    } // testSuggestedUserLimit
        
    static testMethod void testReferToSelfSingleRecord(){
        Account acct = getTestAcct(ACCT1_NAME);
        Contact ctct = acct.Contacts[0];
        Cadence__c cadence = CadenceUpdateTest.getTestCadence();
        
        test.startTest();
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(ctct);
        AddToCadenceController atcc = new AddToCadenceController(stdCtrl);
        system.assertEquals(ctct.Id, atcc.recId);
        System.assertEquals(true,atcc.hasReferOptions);
        atcc.referTo=AddToCadenceController.REFER_SELF;
        atcc.selectedCadence=String.valueOf(cadence.Id);
        
        String label1 = atcc.referOptionLabel;
        System.assertEquals(true,label1.contains('Select a Cadence to'));
        String label2 = atcc.buttonLabel;
        System.assertEquals('Return To '+ctct.Name,label2);
        String limitText = atcc.limitText;
        System.assertEquals(true,atcc.hasCadenceOptions);
        
        atcc.changeReferTo();
        System.assertEquals(false,atcc.referToSelf);
        System.assertEquals(true,atcc.referToElse);
        atcc.changeReferTo();
        System.assertEquals(true,atcc.referToSelf);
        System.assertEquals(false,atcc.referToElse);
        
        atcc.next();
        system.assertEquals(true,atcc.isStepCompleted);
        test.stopTest();
        
        Cadence_Assignment_Record__c[] cars = getCarRecs();
        System.assertEquals(1,cars.size());
        
        Cadence_Assignment_Record__c car = cars[0];
        system.assertEquals(CAROwnershipQueueable.STATUS_SELF,car.SendToPartnerStatus__c);
        System.assertEquals(ctct.Id,car.ContactId__c);
        System.assertEquals(cadence.Id,car.Cadence__c);
    } // testReferToSelfSingleRecord
    
    static testMethod void testLockoutProspectOwnership(){
        User[] users = getTestUsers();
        User u = users[0];
        User poUser = [SELECT id FROM User WHERE isActive = true AND Job_Name__c=:UserHelper.JOB_NSR LIMIT 1];
        Account acct = getTestAcct(ACCT1_NAME);
        Prospect_Ownership__c ownership = new Prospect_Ownership__c(Ownership_Status__c=ProspectOwnershipMethods.STAGE_LOCKOUT,NSR_Name__c=poUser.Id,Prospect_Client__c =acct.Id);
        insert ownership;
        TouchpointSetup__c tpSetup = TouchpointSetup__c.getOrgDefaults();
        
		test.startTest();
        system.runAs(u){
            ApexPages.StandardController stdCtrl = new ApexPages.StandardController(acct);
            AddToCadenceController atcc = new AddToCadenceController(stdCtrl);
            system.assertEquals(acct.Id, atcc.recId);
            atcc.referTo=AddToCadenceController.REFER_ELSE;
            atcc.next();
            system.assertEquals(true,atcc.isStepCompleted);
        }
        test.stopTest();
        
        Cadence_Assignment_Record__c[] cars = getCarRecs();
        System.assertEquals(1,cars.size());
        Cadence_Assignment_Record__c car = cars[0];

        System.assertEquals(acct.Id,car.AccountId__c);
        System.assertEquals(u.Id,car.CreatedById);
        
        system.assertEquals(tpSetup.ATCPOLockout__c,car.SendToPartnerStatusDetail__c);
        system.assertEquals('Closed',car.Status__c);
        system.assertEquals(true,car.Closed__c);
        system.assertEquals(tpSetup.ATCPOLockout__c,car.CloseReason__c);
        system.assertEquals(Date.today(),car.Close_Date__c);
        system.assertEquals(CAROwnershipQueueable.STATUS_FAILED,car.SendToPartnerStatus__c);
        system.assertEquals(ownership.Id,car.SendToPartnerFailedId__c);
    } // testLockoutProspectOwnership
    
    public static Cadence_Assignment_Record__c[] getCarRecs() {
        Cadence_Assignment_Record__c[] cars = [SELECT Id
                                                  ,AccountId__c
                                                  ,AccountId__r.Name
                                                  ,Cadence__c
                                                  ,Cadence__r.Name
                                                  ,Cadence_Owner__c
                                                  ,Closed__c
                                                  ,CloseReason__c
                                                  ,Close_Date__c
                                                  ,ContactId__c
                                                  ,ContactId__r.Name
                                                  ,CreatedById
                                                  ,LeadId__c
                                                  ,LeadId__r.Name
                                                  ,OwnerId
                                                  ,ReferralAccount__c
                                                  ,ReferralAccount__r.Name
                                                  ,SendToPartnerStatus__c
                                                  ,SendToPartnerStatusDetail__c 
                                                  ,SendToPartnerFailedId__c
                                                  ,Status__c
                                                  ,(Select Id, Name, Close_Date__c, Step_Number__c
                                                      From Cadence_Touchpoints__r)
                                              FROM Cadence_Assignment_Record__c];
       return cars;
    } // getCarRecs
    
    static testMethod void testProspectingProspectOwnershipAccount(){
    	User[] users = getTestUsers();
        User u = users[0];
        User nssUser = users[1];
        
        Account acct1 = getTestAcct(ACCT1_NAME);
        Account acct2 = getTestAcct(ACCT2_NAME);
        Account[] accts = new Account[]{acct1,acct2};

        Contact ctct1 = acct1.contacts[0];
        Contact ctct2 = acct2.contacts[0];

        Prospect_Ownership__c ownership1 = new Prospect_Ownership__c(Ownership_Status__c=ProspectOwnershipMethods.STAGE_PROSPECTING,NSR_Name__c=nssUser.Id,Prospect_Client__c=acct1.Id,NSS_Source__c='Outbound');
        Prospect_Ownership__c ownership2 = new Prospect_Ownership__c(Ownership_Status__c=ProspectOwnershipMethods.STAGE_PROSPECTING,NSR_Name__c=nssUser.Id,Prospect_Client__c=acct2.Id,NSS_Source__c='Outbound');
        insert new Prospect_Ownership__c[]{ownership1,ownership2};
                     
        test.startTest();
        system.runAs(u){
            ApexPages.StandardSetController setCtrl = new ApexPages.StandardSetController(accts);
            setCtrl.setSelected(accts);
            AddToCadenceController atcc = new AddToCadenceController(setCtrl);
            system.assertEquals(2, atcc.recIds.size());
            atcc.referTo=AddToCadenceController.REFER_ELSE;
            atcc.next();
            system.assertEquals(true,atcc.isStepCompleted);
        }
        test.stopTest();
        
        Cadence_Assignment_Record__c[] cars = getCarRecs();
        System.assertEquals(2,cars.size());
        TouchpointSetup__c tpSetup = TouchpointSetup__c.getOrgDefaults();
        
        // both should have failed
        for (Cadence_Assignment_Record__c car : cars) {
           System.assertEquals(u.Id,car.CreatedById);
        
           system.assertEquals(tpSetup.ATCPOProspect__c,car.SendToPartnerStatusDetail__c);
           system.assertEquals('Closed',car.Status__c);
           system.assertEquals(true,car.Closed__c);
           system.assertEquals(tpSetup.ATCPOProspect__c,car.CloseReason__c);
           system.assertEquals(Date.today(),car.Close_Date__c);
           system.assertEquals(CAROwnershipQueueable.STATUS_FAILED,car.SendToPartnerStatus__c);
           //system.assertEquals(ownership.Id,car.SendToPartnerFailedId__c);
        }
        

    } // testProspectingProspectOwnershipAccount
    
    static testMethod void testProspectingProspectOwnershipLead(){
    	User[] users = getTestUsers();
        User u = users[0];
        User nssUser = users[1];
        
        Lead lead1 = new Lead(LastName='test lead 1',company='test co1');
        Lead[] leads = new Lead[]{lead1};
        insert leads;
        
        Prospect_Ownership__c ownership1 = new Prospect_Ownership__c(Ownership_Status__c=ProspectOwnershipMethods.STAGE_PROSPECTING,NSR_Name__c=nssUser.Id,Lead__c =lead1.Id,NSS_Source__c='Outbound');
        insert ownership1;
                     
        test.startTest();
        system.runAs(u){
            ApexPages.StandardSetController setCtrl = new ApexPages.StandardSetController(leads);
            setCtrl.setSelected(leads);
            AddToCadenceController atcc = new AddToCadenceController(setCtrl);
            system.assertEquals(1, atcc.recIds.size());
            atcc.referTo=AddToCadenceController.REFER_ELSE;
            atcc.next();
            system.assertEquals(true,atcc.isStepCompleted);
        }
        test.stopTest();
        
        Cadence_Assignment_Record__c[] cars = getCarRecs();
        System.assertEquals(1,cars.size());
        TouchpointSetup__c tpSetup = TouchpointSetup__c.getOrgDefaults();
        
        // both should have failed
        for (Cadence_Assignment_Record__c car : cars) {
           System.assertEquals(u.Id,car.CreatedById);
        
           system.assertEquals(tpSetup.ATCPOProspect__c,car.SendToPartnerStatusDetail__c);
           system.assertEquals('Closed',car.Status__c);
           system.assertEquals(true,car.Closed__c);
           system.assertEquals(tpSetup.ATCPOProspect__c,car.CloseReason__c);
           system.assertEquals(Date.today(),car.Close_Date__c);
           system.assertEquals(CAROwnershipQueueable.STATUS_FAILED,car.SendToPartnerStatus__c);
           //system.assertEquals(ownership.Id,car.SendToPartnerFailedId__c);
        }

    } // testProspectingProspectOwnershipLead
    
    static testMethod void testOpenOppMultipleRecords(){
    	User[] users = getTestUsers();
        User u = users[0];
        User nssUser = users[1];

        Account acct1 = getTestAcct(ACCT1_NAME);
        Account acct2 = getTestAcct(ACCT2_NAME);
        Account[] accts = new Account[]{acct1,acct2};

        Contact ctct1 = acct1.contacts[0];
        Contact ctct2 = acct2.contacts[0];

        Opportunity opp = new Opportunity(Name='test Opp',AccountId = acct1.Id,CloseDate=date.today(),StageName='Create - Received',OwnerId=u.Id);
        Opportunity opp2 = new Opportunity(Name='test Opp2',AccountId = acct1.Id,CloseDate=date.today(),StageName='Create - Received',OwnerId=u.Id);
        Opportunity[] opptys = new Opportunity[]{opp,opp2};
        insert opptys;
        
        test.startTest();
        system.runAs(u){
            ApexPages.StandardSetController setCtrl = new ApexPages.StandardSetController(accts);
            setCtrl.setSelected(accts);
            AddToCadenceController atcc = new AddToCadenceController(setCtrl);
            system.assertEquals(2, atcc.recIds.size());
            atcc.referTo=AddToCadenceController.REFER_ELSE;
            //atcc.tempCar.Telemarketing_Rep__c = nssUser.Id;
            atcc.next();
            system.assertEquals(true,atcc.isStepCompleted);
        }
        test.stopTest();
        
        Cadence_Assignment_Record__c[] cars = getCarRecs();
        System.assertEquals(2,cars.size());
        TouchpointSetup__c tpSetup = TouchpointSetup__c.getOrgDefaults();
        
        Boolean acct1Match = false;
        Boolean acct2Match = false;
        
        for (Cadence_Assignment_Record__c car : cars) {
           if (car.AccountId__c == acct1.Id) {
              acct1Match = true;
              system.assertEquals(tpSetup.ATCOpenOpp__c,car.SendToPartnerStatusDetail__c);
              system.assertEquals('Closed',car.Status__c);
              system.assertEquals(true,car.Closed__c);
              system.assertEquals(tpSetup.ATCOpenOpp__c,car.CloseReason__c);
              system.assertEquals(Date.today(),car.Close_Date__c);
              system.assertEquals(CAROwnershipQueueable.STATUS_FAILED,car.SendToPartnerStatus__c);
           } else if (car.AccountId__c == acct2.Id) {
              acct2Match = true;
           }
        } // for (Cadence_Assignment_Record__c car
        
        System.assertEquals(true,acct1Match);
        System.assertEquals(true,acct2Match);
        
    } // testOpenOppMultipleRecords
    
    static testMethod void testSendMultiple() {
    	User[] users = getTestUsers();
        User u = users[0];
        setCadenceType(u.User_Cadence_Type__c);
        
        Account acct1 = getTestAcct(ACCT1_NAME);
        Account acct2 = getTestAcct(ACCT2_NAME);
        Account acct3 = getTestAcct(ACCT3_NAME);
        Account acct4 = getTestAcct(ACCT4_NAME);
        Account acct5 = getTestAcct(ACCT5_NAME);
        Account[] accts = new Account[]{acct1,acct2,acct3,acct4,acct5};
        
        // add activity for the first 4 accounts
        Task tsk1 = new Task(WhoId=acct1.contacts[0].Id, Subject='Task1', ActivityDate=Date.today(), Status='Completed');
        Task tsk2 = new Task(WhoId=acct2.contacts[0].Id, Subject='Task2', ActivityDate=Date.today(), Status='Completed');
        Task tsk3 = new Task(WhoId=acct3.contacts[0].Id, Subject='Task3', ActivityDate=Date.today(), Status='Completed');
        Task tsk4 = new Task(WhoId=acct4.contacts[0].Id, Subject='Task4', ActivityDate=Date.today(), Status='Completed');
        insert new Task[]{tsk1,tsk2,tsk3,tsk4};
        
        Test.startTest();
        System.runAs(u){
            ApexPages.StandardSetController setCtrl = new ApexPages.StandardSetController(accts);
            setCtrl.setSelected(accts);
            AddToCadenceController atcc = new AddToCadenceController(setCtrl);
            system.assertEquals(5, atcc.recIds.size());
            atcc.referTo=AddToCadenceController.REFER_ELSE;
            atcc.next();
            system.assertEquals(true,atcc.isStepCompleted);
        }
        Test.stopTest();
        
        Cadence_Assignment_Record__c[] cars = getCarRecs();
        System.assertEquals(5,cars.size());
        TouchpointSetup__c tpSetup = TouchpointSetup__c.getOrgDefaults();
        
        Boolean acct1Match = false;
        Boolean acct2Match = false;
        Boolean acct3Match = false;
        Boolean acct4Match = false;
        Boolean acct5Match = false;
        
        for (Cadence_Assignment_Record__c car : cars) {
           if (car.AccountId__r.Name == ACCT1_NAME) {
              acct1Match = true;
              System.assertEquals(CAD_PROSP0_20,car.Cadence__r.Name);
           } else if (car.AccountId__r.Name == ACCT2_NAME) {
              acct2Match = true;
              System.assertEquals(CAD_PROSP21_100,car.Cadence__r.Name);
           } else if (car.AccountId__r.Name == ACCT3_NAME) {
              acct3Match = true;
              System.assertEquals(CAD_CLT0_20,car.Cadence__r.Name);
           } else if (car.AccountId__r.Name == ACCT4_NAME) {
              acct4Match = true;
              System.assertEquals(CAD_CLT21_100,car.Cadence__r.Name);
           } else if (car.AccountId__r.Name == ACCT5_NAME) {
              acct5Match = true;
              System.assertEquals(CAD_PROSP1,car.Cadence__r.Name);
           }
        } // for (Cadence_Assignment_Record__c car

        System.assertEquals(true,acct1Match);
        System.assertEquals(true,acct2Match);
        System.assertEquals(true,acct3Match);
        System.assertEquals(true,acct4Match);
        System.assertEquals(true,acct5Match);
    } // testSendMultiple
    
    static testMethod void testSendMultiple2() {
       // test where some succeed, some fail
       User[] nsrs = [SELECT id FROM User WHERE isActive = true AND Job_Name__c=:UserHelper.JOB_NSR and Assignment_Group_Active__c=true LIMIT 2];
       User nsr1 = nsrs[0];
       User nsr2 = nsrs[1];
       User[] reps = getTestUsers();
       User rep1 = reps[0];
       setCadenceType(rep1.User_Cadence_Type__c);
        
       Account acct1 = getTestAcct(ACCT1_NAME);
       Account acct2 = getTestAcct(ACCT2_NAME);
       Account acct3 = getTestAcct(ACCT3_NAME);
       Account acct4 = getTestAcct(ACCT4_NAME);
       Account acct5 = getTestAcct(ACCT5_NAME);
       Account[] accts = new Account[]{acct1,acct2,acct3,acct4,acct5};
        
       // add activity for the first 4 accounts
       Task tsk1 = new Task(WhoId=acct1.contacts[0].Id, Subject='Task1', ActivityDate=Date.today(), Status='Completed');
       Task tsk2 = new Task(WhoId=acct2.contacts[0].Id, Subject='Task2', ActivityDate=Date.today(), Status='Completed');
       Task tsk3 = new Task(WhoId=acct3.contacts[0].Id, Subject='Task3', ActivityDate=Date.today(), Status='Completed');
       Task tsk4 = new Task(WhoId=acct4.contacts[0].Id, Subject='Task4', ActivityDate=Date.today(), Status='Completed');
       insert new Task[]{tsk1,tsk2,tsk3,tsk4};
            
       Contact ctct1 = acct1.contacts[0];
       Contact ctct2 = acct2.contacts[0];

       Prospect_Ownership__c ownership1 = new Prospect_Ownership__c(Ownership_Status__c=ProspectOwnershipMethods.STAGE_PROSPECTING,NSR_Name__c=nsr1.Id,Prospect_Client__c=acct1.Id,NSS_Source__c='Outbound');
       Prospect_Ownership__c ownership2 = new Prospect_Ownership__c(Ownership_Status__c=ProspectOwnershipMethods.STAGE_LOCKOUT,NSR_Name__c=nsr1.Id,Prospect_Client__c=acct2.Id,NSS_Source__c='Outbound');
       insert new Prospect_Ownership__c[]{ownership1,ownership2};

       Opportunity opp3 = new Opportunity(Name='test Opp3',AccountId = acct3.Id,CloseDate=date.today(),StageName='Create - Received',OwnerId=rep1.Id);
       insert opp3;

       Cadence__c cadProsp1 = getCadence(CAD_PROSP1);
       Cadence__c cadClt21 = getCadence(CAD_CLT21_100);
        
       Assignment_Group_Queues__c[] queues = [Select Id, Name, QueueId__c, Assignment_Group_Name__c 
                                                   from Assignment_Group_Queues__c 
                                                  where QueueId__c=:cadProsp1.SendToPartnerQueueId__c
                                                  order by CreatedDate desc limit 1];
       System.assertEquals(1,queues.size());
       System.debug('testSendMultiple2 adding group member for '+cadProsp1.SendToPartnerQueue__c);
       // add NSR2 to the group for this cadence
       Assignment_Groups__c grpMember = new Assignment_Groups__c(Active__c='True', User__c=nsr2.Id, Group_Name__c=queues[0].Assignment_Group_Name__c);
       insert grpMember;
        
       Test.startTest();
       System.runAs(rep1){
          ApexPages.StandardSetController setCtrl = new ApexPages.StandardSetController(accts);
          setCtrl.setSelected(accts);
          AddToCadenceController atcc = new AddToCadenceController(setCtrl);
          system.assertEquals(5, atcc.recIds.size());
          atcc.referTo=AddToCadenceController.REFER_ELSE;
          atcc.tempCar.Telemarketing_Rep__c=nsr2.Id;
          atcc.tempCar.Description__c='These are awesome leads!';
          atcc.next();
          system.assertEquals(true,atcc.isStepCompleted);
       }
       Test.stopTest();

        Cadence_Assignment_Record__c[] cars = getCarRecs();
        System.assertEquals(5,cars.size());
        TouchpointSetup__c tpSetup = TouchpointSetup__c.getOrgDefaults();
        
        Boolean acct1Match = false;
        Boolean acct2Match = false;
        Boolean acct3Match = false;
        Boolean acct4Match = false;
        Boolean acct5Match = false;

        for (Cadence_Assignment_Record__c car : cars) {
           if (car.AccountId__r.Name == ACCT1_NAME) {
              acct1Match = true;
              System.assertEquals(CAROwnershipQueueable.STATUS_FAILED,car.SendToPartnerStatus__c);
              System.assertEquals(tpSetup.ATCPOProspect__c,car.CloseReason__c);
              System.assertEquals(tpSetup.ATCPOProspect__c,car.SendToPartnerStatusDetail__c);
           } else if (car.AccountId__r.Name == ACCT2_NAME) {
              acct2Match = true;
              System.assertEquals(CAROwnershipQueueable.STATUS_FAILED,car.SendToPartnerStatus__c);
              System.assertEquals(tpSetup.ATCPOLockout__c,car.CloseReason__c);
              System.assertEquals(tpSetup.ATCPOLockout__c,car.SendToPartnerStatusDetail__c);
           } else if (car.AccountId__r.Name == ACCT3_NAME) {
              acct3Match = true;
              System.assertEquals(CAROwnershipQueueable.STATUS_FAILED,car.SendToPartnerStatus__c);
              System.assertEquals(tpSetup.ATCOpenOpp__c,car.CloseReason__c);
              System.assertEquals(tpSetup.ATCOpenOpp__c,car.SendToPartnerStatusDetail__c);
           } else if (car.AccountId__r.Name == ACCT4_NAME) {
              acct4Match = true;
              System.assertEquals(CAROwnershipQueueable.STATUS_QUEUE,car.SendToPartnerStatus__c);
              System.assertEquals(CAD_CLT21_100,car.Cadence__r.Name);
              System.assertEquals(null,car.CloseReason__c);
              System.assertEquals(true,car.SendToPartnerStatusDetail__c.contains('Assigned to Queue'));
              System.assertEquals(cadClt21.SendToPartnerQueueId__c, car.OwnerId);
              System.assertEquals(1,car.Cadence_Touchpoints__r.size());
           } else if (car.AccountId__r.Name == ACCT5_NAME) {
              acct5Match = true;
              System.assertEquals(CAROwnershipQueueable.STATUS_USER,car.SendToPartnerStatus__c);
              System.assertEquals(CAD_PROSP1,car.Cadence__r.Name);
              System.assertEquals(nsr2.Id,car.OwnerId);
              System.assertEquals(nsr2.Id,car.Cadence_Owner__c);
           }
        } // for (Cadence_Assignment_Record__c car

        System.assertEquals(true,acct1Match);
        System.assertEquals(true,acct2Match);
        System.assertEquals(true,acct3Match);
        System.assertEquals(true,acct4Match);
        System.assertEquals(true,acct5Match);

    } // testSendMultiple2
    
    static testMethod void testCheckCadenceOppTypes() {
       Cadence__c cad1 = new Cadence__c(Name='Cad1', Opportunity_Type__c='Type1;Type2;Type3', RepAdd__c=true);
       Cadence__c cad2 = new Cadence__c(Name='Cad2', Opportunity_Type__c='Type3;Type4;Type5', RepAdd__c=true);
       Cadence__c cad3 = new Cadence__c(Name='Cad3', Opportunity_Type__c='Type3;Type6;Type7', RepAdd__c=true);
       Cadence__c cad4 = new Cadence__c(Name='Cad4', Opportunity_Type__c='Type2;Type7;Type8', RepAdd__c=true);
       Cadence__c cad5 = new Cadence__c(Name='Cad5', Opportunity_Type__c='Type1;Type2;Type9', RepAdd__c=true);
       Cadence__c cad6 = new Cadence__c(Name='Cad6', Opportunity_Type__c=null, RepAdd__c=true);
       insert new Cadence__c[]{cad1,cad2,cad3,cad4,cad5,cad6};
       Cadence__c[] cads = new Cadence__c[]{cad1,cad2,cad3,cad4,cad5};
       AddToCadenceController atcc = new AddToCadenceController();
       atcc.checkCadenceOppTypes(new String[]{}, cads);
       System.assertEquals(6,atcc.cadenceOptions.size());
       atcc.checkCadenceOppTypes(new String[]{'Type1','Type9'}, cads);
       System.assertEquals(3,atcc.cadenceOptions.size());
       atcc.checkCadenceOppTypes(new String[]{'Type9'}, cads);
       System.assertEquals(2,atcc.cadenceOptions.size());
       cads.add(cad6);
       atcc.checkCadenceOppTypes(new String[]{'Type1','Type7'}, cads);
       System.assertEquals(6,atcc.cadenceOptions.size());
    } // testCheckCadenceOppTypes
    
    static testMethod void testRfrlAccountSend() {
       User[] reps = getTestUsers();
       User rep1 = reps[0];
       setCadenceType(rep1.User_Cadence_Type__c);

       Referral_Account__c refAcct1 = new Referral_Account__c(Name='Test Account1', Referral_Source_Business_Type__c='Accounting Firm');
       Referral_Account__c refAcct2 = new Referral_Account__c(Name='Test Account2', Referral_Source_Business_Type__c='Something Else');
       Referral_Account__c[] refAccts = new Referral_Account__c[]{refAcct1,refAcct2};
       ReferralAccountMethods.SKIP_TRIGGERS=true;
       insert refAccts;
       
       Test.startTest();
       System.runAs(rep1){
          ApexPages.StandardSetController setCtrl = new ApexPages.StandardSetController(refAccts);
          setCtrl.setSelected(refAccts);
          AddToCadenceController atcc = new AddToCadenceController(setCtrl);
          System.assertEquals(false,atcc.isStepCannotStart);
          System.assertEquals(true,atcc.isStepStart);
          system.assertEquals(2, atcc.recIds.size());
          atcc.referTo=AddToCadenceController.REFER_ELSE;
          //atcc.tempCar.Telemarketing_Rep__c=nsr2.Id;
          atcc.tempCar.Description__c='These are awesome leads!';
          atcc.next();
          system.assertEquals(true,atcc.isStepCompleted);
       }
       Test.stopTest();
        
       Cadence_Assignment_Record__c[] cars = getCarRecs();
       System.assertEquals(2,cars.size());
       TouchpointSetup__c tpSetup = TouchpointSetup__c.getOrgDefaults();
        
       Boolean acct1Match = false;
       Boolean acct2Match = false;

       for (Cadence_Assignment_Record__c car : cars) {
          if (car.ReferralAccount__r.Name == 'Test Account1') {
             acct1Match = true;
             System.assertEquals(CAROwnershipQueueable.STATUS_QUEUE,car.SendToPartnerStatus__c);
             System.assertEquals(null,car.CloseReason__c);
             System.assertEquals(true,car.SendToPartnerStatusDetail__c.contains('Assigned to Queue'));
          } else if (car.ReferralAccount__r.Name == 'Test Account2') {
             acct2Match = true;
             System.assertEquals(CAROwnershipQueueable.STATUS_FAILED,car.SendToPartnerStatus__c);
             System.assertEquals(CAROwnershipQueueable.CLOSE_NO_CADENCE,car.CloseReason__c);
             System.assertEquals(CAROwnershipQueueable.CLOSE_NO_CADENCE,car.SendToPartnerStatusDetail__c);
          }
       } // for (Cadence_Assignment_Record__c car : cars
          
       System.assertEquals(true,acct1Match);
       System.assertEquals(true,acct2Match);

    } // testRfrlAccountSend

} // class AddToCadenceControllerTest