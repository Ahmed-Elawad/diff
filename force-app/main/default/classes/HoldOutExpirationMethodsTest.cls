/* Test of the Hold Out Expiration calculation methods.
   
   History
   -------
   09/15/2015 Cindy Freeman     Created 
   12/07/2015 Cindy Freeman     added code to test Core Events links to different records (acct, contact, opty)
   12/15/2016 Dan Carmen        Change to reduce SOQL statements
   03/27/2017 Cindy Freeman     split into 2 test methods to avoid hitting too many SOQL queries limit
   09/11/2017 Dan Carmen        Add Account_Owner__c field to HoldOut_ExpirationDates__c setup. 
   07/08/2019 Dan Carmen        Change for Core Sales profile move
   07/17/2019 Dan Carmen        Added workflow functionality into the code.
   10/15/2019 Dan Carmen        Change to use TriggerMethods.clearVariables
   12/29/2020 Dan Carmen        Added more custom settings setup
   02/08/2021 Matt Fritschi     Added test for SMB Channel hold out.
   05/19/2021 Dan Carmen        Updated to use IsClosed=true and IsWon=false for not sold opps.
   05/27/2021 Josh Cartwright   added test for APR0116141 only extend holdout when referred by channel lead source  
   06/22/2021 Dan Carmen        Added Contact Field to custom setting
   02/22/2022 Carrie Marciano   Added BenAdmin Holdout fields
   01/23/2023 Dan Carmen        Change Interface, increment API version

 */

@isTest

public class HoldOutExpirationMethodsTest {
   
   @testSetup
   public static void setupData() {
      setupCustomSettings();
      populateSetting();
   } // setupData
   
   public static void setupCustomSettings() {
      TriggerMethodsTest.createTriggerSetting('AccountBefore', true, false, false, false, new String[]{'HoldOutExpirationMethods'});
      TriggerMethodsTest.createTriggerSetting('ContactBefore', true, false, false, false, new String[]{'HoldOutExpirationMethods'});
      TriggerMethodsTest.createTriggerSetting('LeadBefore', true, false, false, false, new String[]{'HoldOutExpirationMethods'});
      TriggerMethodsTest.createTriggerSetting('OpptyAfter', false, true, false, false, new String[]{'HoldOutExpirationMethods'});
       
      TriggerMethodsTest.createTriggerSetting('OpptyBefore', true, false, false, false, new String[]{'OpptyMethods'});
      TriggerMethodsTest.createTriggerSetting('OpptyAfter', false, true, false, false, new String[]{'OpptyMethods'});
      TriggerMethodsTest.saveSetupClasses();

   } // setupCustomSettings
    
   public static HoldOut_ExpirationDates__c hoPAY;
   public static HoldOut_ExpirationDates__c hoMMS;
   public static HoldOut_ExpirationDates__c hoHRS;
   public static HoldOut_ExpirationDates__c hoHNBF;
   public static HoldOut_ExpirationDates__c hoBenAdmin;
   public static HoldOut_ExpirationDates__c hoPAS;
   public static HoldOut_ExpirationDates__c hoMS;
    
   // populated custom setting
   public static void populateSetting() {
      if (HoldOut_ExpirationDates__c.getAll().size() == 0) {
        hoPAY = new HoldOut_ExpirationDates__c(Name='PAY',Sales_Org__c='PAY',Account_Hold_Out__c='Hold_Out__c',Account_Hold_Out_Date__c='Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=30,Account_Date_Field__c='First_Run_Date__c',OptySoldNumberOfDays__c=90,
                                                                          TaskNumberOfDays__c=90,UseForOwnershipChange__c=true,HoldOutReasonFld__c='Permanent_Hold_Out_Description__c'
                                                                          ,Account_Owner__c='OwnerId', Opportunity_Date__c='CloseDate',ContactOwner__c='OwnerId');
        hoMMS = new HoldOut_ExpirationDates__c(Name='MMS',Sales_Org__c='MMS',Account_Hold_Out__c='Hold_Out__c',Account_Hold_Out_Date__c='Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=120,Account_Date_Field__c='First_Run_Date__c',OptySoldNumberOfDays__c=120
                                                                          ,TaskNumberOfDays__c=90,UseForOwnershipChange__c=true,HoldOutReasonFld__c='Permanent_Hold_Out_Description__c'
                                                                          ,Account_Owner__c='OwnerId', Opportunity_Date__c='CloseDate',ContactOwner__c='OwnerId');
        hoHRS = new HoldOut_ExpirationDates__c(Name='HRS',Sales_Org__c='HRS',Account_Hold_Out__c='HRS_Hold_Out__c',Account_Hold_Out_Date__c='HRS_Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=180,Opportunity_Date__c='CloseDate',OptySoldNumberOfDays__c=180
                                                                          ,TaskNumberOfDays__c=90,HoldOutReasonFld__c='HRS_Permanent_Hold_Out_Description__c'
                                                                          ,UseForOwnershipChange__c=true, Account_Owner__c='HRS_Account_Owner__c',ContactOwner__c='HRS_Contact_Owner__c'
                                                                          ,AccountTeamRole__c='Small Market 401(k) Partner');
        hoHNBF = new HoldOut_ExpirationDates__c(Name='HNBF',Sales_Org__c='HNBF',Account_Hold_Out__c='HNBF_Hold_Out__c',Account_Hold_Out_Date__c='HNBF_Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=180,Opportunity_Date__c='CloseDate',OptySoldNumberOfDays__c=180
                                                                          ,UseForOwnershipChange__c=true, Account_Owner__c='HNBF_Account_Owner__c',ContactOwner__c='HNBF_Contact_Owner__c'
                                                                          ,AccountTeamRole__c='H&B Partner');
        hoBenAdmin = new HoldOut_ExpirationDates__c(Name='BenAdmin',Sales_Org__c='BenAdmin',Account_Hold_Out__c='BenAdmin_Hold_Out__c',Account_Hold_Out_Date__c='BenAdmin_Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=180,Opportunity_Date__c='CloseDate',OptySoldNumberOfDays__c=180
                                                                          ,UseForOwnershipChange__c=true,ContactOwner__c='OwnerId',AccountTeamRole__c='BenAdmin Sales Rep');  
        hoPAS = new HoldOut_ExpirationDates__c(Name='PAS',Sales_Org__c='PAS',Account_Hold_Out__c='Premier_PBS_Hold_Out__c',Account_Hold_Out_Date__c='Premier_PBS_Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=180,Opportunity_Date__c='CloseDate',OptySoldNumberOfDays__c=180
                                                                          ,TaskNumberOfDays__c=90,UseForOwnershipChange__c=true,HoldOutReasonFld__c='PEO_ASO_Permanent_Hold_Out_Description__c'
                                                                          ,Account_Owner__c='Premier_PBS_Account_Owner__c',ContactOwner__c='Premier_PBS_Contact_Owner__c'
                                                                          ,AccountTeamRole__c='PEO-ASO Partner');
        hoMS = new HoldOut_ExpirationDates__c(Name='MS',Sales_Org__c='MS',Account_Hold_Out__c='MS_Hold_Out__c',Account_Hold_Out_Date__c='MS_Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=null,Opportunity_Date__c=null,OptySoldNumberOfDays__c=null
                                                                          ,UseForOwnershipChange__c=true,ContactOwner__c='OwnerId'
                                                                          ,AccountTeamRole__c='Merchant Services Representative');
        HoldOut_ExpirationDates__c[] hoList = new HoldOut_ExpirationDates__c[]{hoPAY,hoMMS, hoHRS, hoHNBF, hoBenAdmin, hoPAS,hoMS};
        insert hoList;
     } else {
        hoPAY = HoldOut_ExpirationDates__c.getInstance('PAY');
        hoMMS = HoldOut_ExpirationDates__c.getInstance('MMS');
        hoHRS = HoldOut_ExpirationDates__c.getInstance('HRS');
        hoHNBF = HoldOut_ExpirationDates__c.getInstance('HNBF');
        hoBenAdmin = HoldOut_ExpirationDates__c.getInstance('BenAdmin'); 
        hoPAS = HoldOut_ExpirationDates__c.getInstance('PAS');
        hoMS = HoldOut_ExpirationDates__c.getInstance('MS');
     }
   } // populateSetting
    
    /** Create an account and contacts for testing purposes.
     */
    private static Account createAccount(Id ownerId, Id hrsOwnerId, Id pasOwnerId, Id hnbfOwnerId) {
        // create account and contacts owned by u1
        Account acct = new Account(Name = 'test', OwnerId = ownerId, HRS_Account_Owner__c=hrsOwnerId, 
                                   Premier_PBS_Account_Owner__c=pasOwnerId, HNBF_Account_Owner__c=hnbfOwnerId);
        insert acct;                
        Contact c1 = new Contact (FirstName='Jimmy', LastName='Test', OwnerId=ownerId, AccountId=acct.Id
                                 ,HRS_Contact_Owner__c = hrsOwnerId ,Premier_PBS_Contact_Owner__c = pasOwnerId
                                 ,HNBF_Contact_Owner__c = hnbfOwnerId);
        Contact c2 = new Contact (FirstName='Jenny', LastName='Test', OwnerId=ownerId, AccountId=acct.Id
                                 ,HRS_Contact_Owner__c = hrsOwnerId ,Premier_PBS_Contact_Owner__c = pasOwnerId
                                 ,HNBF_Contact_Owner__c = hnbfOwnerId);
        Contact[] ctcts = new Contact[]{c1,c2};
        insert ctcts;
        
        return acct;
    } // createAccount
    
    private static Transfer_Request__c createRequest(Id acctId, Id ownerId, Id acctOwnerId, String ownerField, String ownerType,Id taskId) {
       Transfer_Request__c tr = new Transfer_Request__c (OwnerId = ownerId, Owner_Field__c=ownerField,Owner_Type__c = ownerType,Account__c = acctId, Account_Owner__c = acctOwnerId
                                                        ,TaskId__c = taskId
                                                        ,Comments__c = 'Request for Transfer');
       /*
       insert tr;
       if (createTask) {
          Task t1 = new Task(OwnerId = ownerId, Subject='TEST1', Type='TEST1', WhatId=acctId, ActivityDate=Date.today());
          insert t1;
          // link the task
          tr.TaskId__c = t1.Id;
          update tr;
       }
       tr = [select Id, Account__c, Account_Owner__c, Comments__c, Status__c, Owner_Field__c, Owner_Type__c,TaskId__c from Transfer_Request__c where Id = :tr.Id];
              */
       
       return tr;
    } // createRequest

    static testMethod void testInitial() {
        populateSetting();
        User[] coreUsers = [select Id,Sales_Org__c from User where Profile.Name in :Utilities.CORE_PROFS and isActive=true and Sales_Org__c='PAY' limit 2];
        User u1 = coreUsers[0];
        User u2 = coreUsers[1];
        User[] hrsUsers = [select Id,Sales_Org__c from User where Profile.Name like 'HRS 401(k) Sales - SB' and isActive=true and Sales_Org__c='HRS' limit 2];
        User uHRS1 = hrsUsers[0];
        User uHRS2 = hrsUsers[1]; 
        User[] peoUsers = [select Id,Sales_Org__c from User where Profile.Name='HRS PEO-ASO Sales - SB' and isActive=true and Sales_Org__c='PAS' limit 2];
        User uPEO1 = peoUsers[0];
        User uPEO2 = peoUsers[1];
        User[] hnbUsers = [select Id,Sales_Org__c from User where Profile.Name='HNBF Sales Rep' and isActive=true and Sales_Org__c='HNBF' limit 2]; 
        User uHNBF1 = hnbUsers[0];
        User uHNBF2 = hnbUsers[1];

        Account acct = createAccount(u1.Id,uHRS1.Id,uPEO1.Id,uHNBF1.Id);

        Task tskCore2 = new Task(OwnerId = u2.Id, Subject='TEST1', Type='TEST1', WhatId=acct.Id, ActivityDate=Date.today());
        Task tskPeo2 = new Task(OwnerId = uPEO2.Id, Subject='TEST1', Type='TEST1', WhatId=acct.Id, ActivityDate=Date.today());        
        Task[] tsks = new Task[]{tskCore2,tskPeo2};
        insert tsks;
        
        Transfer_Request__c trCore2=createRequest(acct.Id, u2.Id, acct.OwnerId, CrossoverRequestController.OWNER_MAIN,u2.Sales_Org__c,tskCore2.Id);
        Transfer_Request__c trPeo2=createRequest(acct.Id, uPEO2.Id, acct.Premier_PBS_Account_Owner__c, CrossoverRequestController.OWNER_PREMIER,uPEO2.Sales_Org__c,tskPeo2.Id);
        Transfer_Request__c[] requests = new Transfer_Request__c[]{trCore2,trPeo2};
        insert requests;
        
        // change the status to Approved
        for (Transfer_Request__c tr : requests) {
         system.debug('tr: '+tr);
           tr.Status__c = CrossoverRequestController.STATUS_APPROVED;
        }
        //Test.startTest();
        update requests;
        //Test.stopTest();
        
        acct = [select Id, OwnerId, HRS_Account_Owner__c, Premier_PBS_Account_Owner__c
                        ,Hold_Out_Expiration__c, Hold_Out__c                    
                        ,HRS_Hold_Out_Expiration__c, HRS_Hold_Out__c
                        ,HNBF_Hold_Out_Expiration__c, HNBF_Hold_Out__c
                		,BenAdmin_Hold_Out_Expiration__c, BenAdmin_Hold_Out__c
                        ,Premier_PBS_Hold_Out_Expiration__c, Premier_PBS_Hold_Out__c
                from Account where Id=:acct.Id];
          
        Map<String, HoldOut_ExpirationDates__c> allHODates = new Map<String, HoldOut_ExpirationDates__c>();
        allHODates = HoldOut_ExpirationDates__c.getAll();
        System.assertEquals(7, allHODates.size());
        // check Hold Out expiration dates
        Date beginDate = System.today();
        HoldOut_ExpirationDates__c hoDates = HoldOut_ExpirationDates__c.getInstance('PAY');        
        Date newDate = beginDate.addDays((Integer)hoDates.InitialNumberOfDays__c);
        System.assertEquals(acct.Hold_Out_Expiration__c, newDate);
        hoDates = HoldOut_ExpirationDates__c.getInstance('PAS');        
        newDate = beginDate.addDays((Integer)hoDates.InitialNumberOfDays__c);
        System.assertEquals(acct.Premier_PBS_Hold_Out_Expiration__c, newDate);
  
        hoDates = HoldOut_ExpirationDates__c.getInstance('PAY');  
        // revise Hold Out due to Core Event being created
        Schema.RecordTypeInfo evntCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_EVENT, ObjectHelper.OBJECT_EVENT);
        Event coreEvnt = new Event(recordTypeID =evntCorert.getRecordTypeId(),type='Presentation - Initial',whatId=acct.Id,DurationInMinutes=60,
                                  ActivityDateTime=System.Now());
        insert coreEvnt;
        acct = [select Id, OwnerId, First_Run_Date__c, Hold_Out_Expiration__c, Hold_Out__c from Account where Id=:acct.Id];
        newDate = beginDate.addDays((Integer)hoDates.TaskNumberOfDays__c);
        System.assertEquals(acct.Hold_Out_Expiration__c, newDate);
        
        // revise Hold Out due to Core Opty being Sold        
        acct.First_Run_Date__c = Date.today();
        update acct;
        Schema.RecordTypeInfo optyCorert = RecordTypeHelper.getRecordType('Core Opportunity Record Type', ObjectHelper.OBJECT_OPPTY);
        Opportunity coreOpty = new Opportunity(recordTypeID = optyCorert.getRecordTypeId(), name='test Core Opty',
                                               AccountId=acct.Id, Stagename = 'Pending',
                                               CloseDate=Date.today(),OwnerId=acct.OwnerId);
        insert coreOpty; 
        coreOpty.Stagename = 'Sold';
        coreOpty.Service_Location__c='Rochester Branch 0017';
        update coreOpty;
        
        acct = [select Id, OwnerId,First_Run_Date__c, Hold_Out_Expiration__c, Hold_Out__c from Account where Id=:acct.Id];
        beginDate = acct.First_Run_Date__c;
        newDate = beginDate.addDays((Integer)hoDates.OptySoldNumberOfDays__c);
        System.assertEquals(acct.Hold_Out_Expiration__c, newDate);
  
    } // testInitial

  static testMethod void testHRSHNBF() {
        populateSetting();
        User[] coreUsers = [select Id,Sales_Org__c from User where Profile.Name in :Utilities.CORE_PROFS and isActive=true and Sales_Org__c='PAY' limit 2];
        User u1 = coreUsers[0];
        User u2 = coreUsers[1];
        User[] hrsUsers = [select Id,Sales_Org__c from User where Profile.Name like 'HRS 401(k) Sales - SB' and isActive=true and Sales_Org__c='HRS' limit 2];
        User uHRS1 = hrsUsers[0];
        User uHRS2 = hrsUsers[1]; 
        User[] peoUsers = [select Id,Sales_Org__c from User where Profile.Name='HRS PEO-ASO Sales - SB' and isActive=true and Sales_Org__c='PAS' limit 2];
        User uPEO1 = peoUsers[0];
        User uPEO2 = peoUsers[1];
        User[] hnbUsers = [select Id,Sales_Org__c from User where Profile.Name='HNBF Sales Rep' and isActive=true and Sales_Org__c='HNBF' limit 2]; 
        User uHNBF1 = hnbUsers[0];
        User uHNBF2 = hnbUsers[1];

        Account acct = createAccount(u1.Id,uHRS1.Id,uPEO1.Id,uHNBF1.Id);

        Task tskHrs2 = new Task(OwnerId = uHRS2.Id, Subject='TEST1', Type='TEST1', WhatId=acct.Id, ActivityDate=Date.today());
        Task tskHnbf2 = new Task(OwnerId = uHNBF2.Id, Subject='TEST1', Type='TEST1', WhatId=acct.Id, ActivityDate=Date.today());
        Task[] tsks = new Task[]{tskHrs2,tskHnbf2};
        insert tsks;
        
        Transfer_Request__c trHrs2=createRequest(acct.Id, uHRS2.Id, acct.HRS_Account_Owner__c, CrossoverRequestController.OWNER_HRS,uHRS2.Sales_Org__c,tskHrs2.Id);
        Transfer_Request__c trHnbf2=createRequest(acct.Id, uHNBF2.Id, acct.HNBF_Account_Owner__c, CrossoverRequestController.OWNER_HNB,uHNBF2.Sales_Org__c,tskHnbf2.Id);
        Transfer_Request__c[] requests = new Transfer_Request__c[]{trHrs2,trHnbf2};
        insert requests;
        
        // change the status to Approved
        for (Transfer_Request__c tr : requests) {
         system.debug('tr: '+tr);
           tr.Status__c = CrossoverRequestController.STATUS_APPROVED;
        }
        //Test.startTest();
        update requests;
        //Test.stopTest();
        
        acct = [select Id, OwnerId, HRS_Account_Owner__c, Premier_PBS_Account_Owner__c
                        ,Hold_Out_Expiration__c, Hold_Out__c                    
                        ,HRS_Hold_Out_Expiration__c, HRS_Hold_Out__c
                        ,HNBF_Hold_Out_Expiration__c, HNBF_Hold_Out__c
                		,BenAdmin_Hold_Out_Expiration__c, BenAdmin_Hold_Out__c
                        ,Premier_PBS_Hold_Out_Expiration__c, Premier_PBS_Hold_Out__c
                from Account where Id=:acct.Id];
          
        Map<String, HoldOut_ExpirationDates__c> allHODates = new Map<String, HoldOut_ExpirationDates__c>();
        allHODates = HoldOut_ExpirationDates__c.getAll();
        System.assertEquals(7, allHODates.size());
        // check Hold Out expiration dates
        Date beginDate = System.today();
        HoldOut_ExpirationDates__c hoDates = HoldOut_ExpirationDates__c.getInstance('HRS');
        system.debug(hoDates);        
        Date newDate = beginDate.addDays((Integer)hoDates.InitialNumberOfDays__c);
        System.assertEquals(acct.HRS_Hold_Out_Expiration__c, newDate);
        hoDates = HoldOut_ExpirationDates__c.getInstance('HNBF');        
        newDate = beginDate.addDays((Integer)hoDates.InitialNumberOfDays__c);
        System.assertEquals(acct.HNBF_Hold_Out_Expiration__c, newDate);
 
       // revise HRS expiration date due to HRS opty being Sold
        hoDates = HoldOut_ExpirationDates__c.getInstance('HRS');  
        Schema.RecordTypeInfo optyHRSrt = RecordTypeHelper.getRecordType('HRS 401(k) Opportunity Record Type', ObjectHelper.OBJECT_OPPTY);
        Opportunity hrsOpty = new Opportunity(recordTypeID = optyHRSrt.getRecordTypeId(), name='test HRS Opty',
                                               AccountId=acct.Id, Stagename = 'Pending',
                                               CloseDate=Date.today(),OwnerId=acct.OwnerId);
        insert hrsOpty; 
        hrsOpty.Stagename = 'Sold:';
        hrsOpty.Service_Location__c='401k Rochester';
        update hrsOpty;
        
        acct = [select Id, OwnerId,First_Run_Date__c, HRS_Hold_Out_Expiration__c, HRS_Hold_Out__c from Account where Id=:acct.Id];
        beginDate = hrsOpty.CloseDate;
        newDate = beginDate.addDays((Integer)hoDates.OptySoldNumberOfDays__c);
        System.assertEquals(acct.HRS_Hold_Out_Expiration__c, newDate);
        
        // revise HNBF expiration date due to HNBF opty being Sold
        hoDates = HoldOut_ExpirationDates__c.getInstance('HNBF');  
        Schema.RecordTypeInfo optyHNBFrt = RecordTypeHelper.getRecordType('HNBF Opportunity Record Type', ObjectHelper.OBJECT_OPPTY);
        Opportunity hnbfOpty = new Opportunity(recordTypeID = optyHNBFrt.getRecordTypeId(), name='test HNBF Opty',
                                               AccountId=acct.Id, Stagename = 'Pending',
                                               CloseDate=Date.today(),OwnerId=acct.OwnerId);
        insert hnbfOpty; 
        hnbfOpty.Stagename = 'Sold - Submitted';
        update hnbfOpty;
        
        acct = [select Id, OwnerId,First_Run_Date__c, HNBF_Hold_Out_Expiration__c, HNBF_Hold_Out__c from Account where Id=:acct.Id];
        beginDate = hnbfOpty.CloseDate;
        newDate = beginDate.addDays((Integer)hoDates.OptySoldNumberOfDays__c);
        System.assertEquals(acct.HNBF_Hold_Out_Expiration__c, newDate);
        
    } // testHRSHNBF

   static testMethod void testHoldouts() {
      populateSetting();
      Account acct1 = new Account(Name='Acct1', Hold_Out__c=true, Hold_Out_Expiration__c=Date.today().addDays(7), Permanent_Hold_Out_Description__c='TEST');
      acct1.HRS_Hold_Out__c=true;
      acct1.HRS_Hold_Out_Expiration__c=Date.today().addDays(11);
      acct1.Premier_PBS_Hold_Out__c=true;
      acct1.Premier_PBS_Hold_Out_Expiration__c=Date.today().addDays(5);
      insert acct1;
      
      acct1=getAcct(acct1.Id);
      System.assertEquals(Date.today().addDays(5), acct1.HoldOutCheckDate__c);
      
      TriggerMethods.clearVariables();
      acct1.Premier_PBS_Hold_Out__c=false;
      update acct1;
      
      acct1=getAcct(acct1.Id);
      System.assertEquals(Date.today().addDays(7), acct1.HoldOutCheckDate__c);
      System.assertEquals(false,acct1.Premier_PBS_Hold_Out__c);
      System.assertEquals(null,acct1.Premier_PBS_Hold_Out_Expiration__c);

      TriggerMethods.clearVariables();
      acct1.Hold_Out__c=false;
      update acct1;
      acct1=getAcct(acct1.Id);
      System.assertEquals(Date.today().addDays(11), acct1.HoldOutCheckDate__c);
      System.assertEquals(false,acct1.Hold_Out__c);
      System.assertEquals(null,acct1.Hold_Out_Expiration__c);
      System.assertEquals(null,acct1.Permanent_Hold_Out_Description__c);

      
      Contact ctct1 = new Contact(AccountId=acct1.Id, FirstName='First', LastName='LastName1', Hold_Out__c=true, Hold_Out_Expiration__c=Date.today().addDays(7), Hold_Out_Reason__c='Testing');
      insert ctct1;
      
      ctct1 = [select Name, Hold_Out__c, Hold_Out_Expiration__c from Contact where Id=:ctct1.Id];
      ctct1.Hold_Out__c=false;
      TriggerMethods.clearVariables();
      update ctct1;

      ctct1 = [select Name, Hold_Out__c, Hold_Out_Expiration__c, Hold_Out_Reason__c from Contact where Id=:ctct1.Id];
      System.assertEquals(null,ctct1.Hold_Out_Expiration__c);
      System.assertEquals(null,ctct1.Hold_Out_Reason__c);
      
      Lead ld1 = new Lead(LastName='Lead1', Company='LeadCompany1', Hold_Out__c=true, Hold_Out_Expiration__c=Date.today().addDays(7), Hold_Out_Reason__c='Testing');
      insert ld1;
      
      ld1.Hold_Out__c=false;
      TriggerMethods.clearVariables();
      TriggerMethods.clearVariables();
      update ld1;
      
      ld1 = [Select Id, Name, Hold_Out__c, Hold_Out_Expiration__c, Hold_Out_Reason__c from Lead where Id=:ld1.Id];
      System.assertEquals(false,ld1.Hold_Out__c);
      System.assertEquals(null,ld1.Hold_Out_Expiration__c);
      System.assertEquals(null,ld1.Hold_Out_Reason__c);
   } // testHoldouts
   
   public static Account getAcct(Id acctId) {
      Account acct=[Select Id, Name, HoldOutCheckDate__c, Hold_Out__c, Hold_Out_Expiration__c, Permanent_Hold_Out_Description__c
                             ,HRS_Hold_Out__c, HRS_Hold_Out_Expiration__c, Premier_PBS_Hold_Out__c, Premier_PBS_Hold_Out_Expiration__c
              from Account where Id=:acctId];
      return acct;
   } // getAcct
    
   static testMethod void testSoldHoldOutDictionary() {
      // scenarios to handle when oppty goes sold
      // hold out expiration is removed
      HoldOut_Dictionary__c hod1 = new HoldOut_Dictionary__c(Name='HoldOut1',InitialNbrDays__c=30,Next_HO_reason__c=null, Permanent__c=false, Sold_clears_Expiration_Date__c=true, SoldExtendsHoldout__c=null, Use_Opty_Owner__c=false );
      // hold out date is removed, but stays permanent
      HoldOut_Dictionary__c hod2 = new HoldOut_Dictionary__c(Name='HoldOut2',InitialNbrDays__c=30,Next_HO_reason__c=null, Permanent__c=true, Sold_clears_Expiration_Date__c=true, SoldExtendsHoldout__c=null, Use_Opty_Owner__c=false );
      // hold out date is updated to new number of days, hold out doesn't change
      HoldOut_Dictionary__c hod3 = new HoldOut_Dictionary__c(Name='HoldOut3',InitialNbrDays__c=30,Next_HO_reason__c=null, Permanent__c=true, Sold_clears_Expiration_Date__c=false, SoldExtendsHoldout__c=60, Use_Opty_Owner__c=false );
      // hold out date is removed, new hold out reason is set
      HoldOut_Dictionary__c hod4 = new HoldOut_Dictionary__c(Name='HoldOut4',InitialNbrDays__c=30,Next_HO_reason__c='HoldOut4a', Permanent__c=false, Sold_clears_Expiration_Date__c=true, SoldExtendsHoldout__c=null, Use_Opty_Owner__c=false );
      // hold out date is removed, new hold out reason is set
      HoldOut_Dictionary__c hod5 = new HoldOut_Dictionary__c(Name='HoldOut5',InitialNbrDays__c=30,Next_HO_reason__c='HoldOut5a', Permanent__c=false, Sold_clears_Expiration_Date__c=false, SoldExtendsHoldout__c=null, Use_Opty_Owner__c=false );
      // when an opp goes to not sold, hold out is removed.
      HoldOut_Dictionary__c hod6 = new HoldOut_Dictionary__c(Name='HoldOut6',InitialNbrDays__c=30,Next_HO_reason__c=null, Permanent__c=false, Sold_clears_Expiration_Date__c=false, SoldExtendsHoldout__c=null, Use_Opty_Owner__c=false, Not_Sold_clears_Hold_Out__c=true );
      //When an opp goes to not sold owned by SMB Channel rep, Hold Out is extended to 12 months.
      HoldOut_Dictionary__c hod7 = new HoldOut_Dictionary__c(Name='Not Sold Opportunity',InitialNbrDays__c=365,Next_HO_reason__c=null, Permanent__c=false, Sold_clears_Expiration_Date__c=false, SoldExtendsHoldout__c=null, Use_Opty_Owner__c=true, Not_Sold_clears_Hold_Out__c=false, Min_Employees__c = 1, Max_Employees__c = 19 );
      HoldOut_Dictionary__c[] hods = new HoldOut_Dictionary__c[]{hod1,hod2,hod3,hod4,hod5,hod6,hod7};
      insert hods;
       
       HoldOutExpirationMethods.referralLS = new Set <string>{'Acquisition'}; 

      
      User[] users = [Select Id, Name from user where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 6];
      Account acct1 = new Account(Name='Account1', OwnerId=users[0].Id, Hold_Out__c=true, Hold_Out_Expiration__c=Date.today().addDays(2), Permanent_Hold_Out_Description__c=hod1.Name);
      Account acct2 = new Account(Name='Account2', OwnerId=users[1].Id, Hold_Out__c=true, Hold_Out_Expiration__c=Date.today().addDays(2), Permanent_Hold_Out_Description__c=hod2.Name);
      Account acct3 = new Account(Name='Account3', OwnerId=users[2].Id, Hold_Out__c=true, Hold_Out_Expiration__c=Date.today().addDays(2), Permanent_Hold_Out_Description__c=hod3.Name);
      Account acct4 = new Account(Name='Account4', OwnerId=users[3].Id, Hold_Out__c=true, Hold_Out_Expiration__c=Date.today().addDays(2), Permanent_Hold_Out_Description__c=hod4.Name);
      Account acct5 = new Account(Name='Account5', OwnerId=users[4].Id, First_Run_Date__c=Date.today().addDays(1));
      Account acct6 = new Account(Name='Account6', OwnerId=users[5].Id, Hold_Out__c=true, Hold_Out_Expiration__c=Date.today().addDays(2), Permanent_Hold_Out_Description__c=hod6.Name);
       
      User[] smbUser = [Select Id, Name from user where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Division__c = 'SMB Channel' limit 1];
      Account acct7 = new Account(Name='Account7', OwnerId=smbUser[0].Id, Hold_Out__c=true, Hold_Out_Expiration__c=Date.today().addDays(2), Permanent_Hold_Out_Description__c=hod6.Name, NumberOfEmployees=5);
       
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4,acct5,acct6,acct7};
      insert accts;

      // create a referral partner
      Referral_Partner__c refPartner5 = new Referral_Partner__c(Name='RefPartner', Partner_Type__c='NSS', Permanent_Hold_Out_Description__c=hod5.Name);
      insert refPartner5;
       
      Referral__c ref5 = new Referral__c(Name='Referral', Account__c=acct5.Id, Referral_Partner__c=refPartner5.Id);
      insert ref5;

      Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, 'Opportunity');
      Id coreRtId = coreRt.getRecordTypeId();
      Opportunity opp1 = new Opportunity(Name='Opp1', AccountId=acct1.Id, LeadSource='Acquisition',  RecordTypeId=coreRtId, CloseDate=Date.today().addDays(1), StageName='Pending', Payroll_Unit__c=true);
      Opportunity opp2 = new Opportunity(Name='Opp2', AccountId=acct2.Id, RecordTypeId=coreRtId, CloseDate=Date.today().addDays(1), StageName='Pending', Payroll_Unit__c=true);
      Opportunity opp3 = new Opportunity(Name='Opp3', AccountId=acct3.Id, RecordTypeId=coreRtId, CloseDate=Date.today().addDays(1), StageName='Pending', Payroll_Unit__c=true);
      Opportunity opp4 = new Opportunity(Name='Opp4', AccountId=acct4.Id, RecordTypeId=coreRtId, CloseDate=Date.today().addDays(1), StageName='Pending', Payroll_Unit__c=true);
      Opportunity opp5 = new Opportunity(Name='Opp5', AccountId=acct5.Id, RecordTypeId=coreRtId, CloseDate=Date.today().addDays(1), StageName='Pending', Payroll_Unit__c=true, ReferralLookup__c=ref5.Id);
      Opportunity opp6 = new Opportunity(Name='Opp6', AccountId=acct6.Id, RecordTypeId=coreRtId, CloseDate=Date.today().addDays(1), StageName=Label.OppStage_IEUP, Probability=30, Payroll_Unit__c=true);
      Opportunity opp7 = new Opportunity(Name='Opp7', OwnerId = acct7.OwnerId, AccountId=acct7.Id, LeadSource='Acquisition', RecordTypeId=coreRtId, CloseDate=Date.today().addDays(1), StageName=Label.OppStage_IEUP, Probability=30, Payroll_Unit__c=true, Type = 'Payroll');
      Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3,opp4,opp5,opp6,opp7};
      insert opps;
       
      opp1.Service_Location__c='Payroll';
      opp1.StageName='Sold';
      opp2.Service_Location__c='Payroll';
      opp2.StageName='Sold';
      opp3.Service_Location__c='Payroll';
      opp3.StageName='Sold';
      opp4.Service_Location__c='Payroll';
      opp4.StageName='Sold';
      opp5.Service_Location__c='Payroll';
      opp5.StageName='Sold';
      opp6.StageName=Label.OppStage_Lost;
      opp7.StageName=Label.OppStage_Lost;
       
      Test.startTest();
      TriggerMethods.clearVariables();
      update opps;
      Test.stopTest();
       
      Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Name, Hold_Out__c, Hold_Out_Expiration__c, Permanent_Hold_Out_Description__c from Account]);
      Account checkAcct1 = acctMap.get(acct1.id);
      System.assertEquals(false, checkAcct1.Hold_Out__c);
      System.assertEquals(null, checkAcct1.Hold_Out_Expiration__c);
      System.assertEquals(null, checkAcct1.Permanent_Hold_Out_Description__c);
      
      Account checkAcct2 = acctMap.get(acct2.id);
      System.assertEquals(true, checkAcct2.Hold_Out__c);
      System.assertEquals(null, checkAcct2.Hold_Out_Expiration__c);
      System.assertEquals(hod2.Name, checkAcct2.Permanent_Hold_Out_Description__c);
       
      Account checkAcct3 = acctMap.get(acct3.id);
      System.assertEquals(true, checkAcct3.Hold_Out__c);
      System.assertEquals(opp3.CloseDate.addDays(60), checkAcct3.Hold_Out_Expiration__c);
      System.assertEquals(hod3.Name, checkAcct3.Permanent_Hold_Out_Description__c);
       
      Account checkAcct4 = acctMap.get(acct4.id);
      System.assertEquals(true, checkAcct4.Hold_Out__c);
      System.assertEquals(null, checkAcct4.Hold_Out_Expiration__c);
      System.assertEquals(hod4.Next_HO_reason__c, checkAcct4.Permanent_Hold_Out_Description__c);
       
      Account checkAcct5 = acctMap.get(acct5.id);
      System.assertEquals(true, checkAcct5.Hold_Out__c);
      System.assertEquals(acct5.First_Run_Date__c.addDays(90), checkAcct5.Hold_Out_Expiration__c);
      System.assertEquals(hod5.Next_HO_reason__c, checkAcct5.Permanent_Hold_Out_Description__c);
       
      Account checkAcct6 = acctMap.get(acct6.id);
      System.assertEquals(false, checkAcct6.Hold_Out__c);
      System.assertEquals(null, checkAcct6.Hold_Out_Expiration__c);
      System.assertEquals(null, checkAcct6.Permanent_Hold_Out_Description__c);
       
      Account checkAcct7 = acctMap.get(acct7.id);
      System.assertEquals(true, checkAcct7.Hold_Out__c);
      System.assertEquals(System.Date.today()+365, checkAcct7.Hold_Out_Expiration__c);
      System.assertEquals('Not Sold Opportunity', checkAcct7.Permanent_Hold_Out_Description__c);
   } // testHoldOutDictionary
  
    
} // class HoldOutExpirationMethodsTes