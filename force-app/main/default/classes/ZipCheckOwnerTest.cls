/* Test Methods for the ZipCheckOwner class
   
  History
  -------
  05/25/2012 Dan Carmen    Created from AccountCheckOwnerTest
  12/12/2012 Dan Carmen   Added asset criteria
  05/14/2013 Dan Carmen   Removed specific DSR logic
  05/22/2013 Dan Carmen   Added check for bad zip codes for referral accounts.
  06/04/2015 Dan Carmen   Changes to work with Referrals
  08/03/2015 Cindy Freeman  changed labels for 401k acct team roles to Small and Large Markets,  modified test segment for Large Market 401k
   09/29/2016 Dan Carmen    Move contact ownership to the before trigger.
  12/15/2017 Cindy Freeman  add some tests for some miscellaneous ZipCheckOwner methods
  06/11/2018 Cindy Freeman  add test for PEO Centric Leads
  05/13/2019 Jacob Hinds    changing some pas stuff to peo
  05/13/2020 Dan Carmen     Changes for new PEO Owner field
  12/31/2020 Dan Carmen     Add reason field for hold out check
  08/16/2021 Josh Cartwright updated test to pull in selling start date
  11/08/2021 Jermaine Stukes    Removed references to external wholesaler owner fields
  01/04/2022 Dan Carmen         Move logic from the AccountAfter trigger to ZipCheckOwner
  03/04/2022 Dan Carmen         Clean up some ownership logic
  09/15/2022 Shilpa G           Added Lost Client Ownership logic
  03/02/2023 Rohit Ranjan   Added testPEOClient()
  11/07/2023 Eric Porter     Updated TestPeoClient method to include new fields on new Opptys (Pain_Points__c, What_Brought_Them_To_Paychex__c, and Products_Of_Interest__c).
  01/02/2024 Dan Carmen        Additional linkage for ZipSegmentCriteriaLink__c for more flexibility
  01/25/2024 Shilpa G      APR0161315: Added method 'testProspectRecordTypeChange' to verify the record type change in case of MMS prospects between 10-19 ee
  04/24/2024 Shilpa G      APR0157517: Added method testClearSalesAccountTeams
  06/05/2024 Shilpa G      APR0164310: Added method testClientTypeZipCriteria

*/
 
@isTest 
public class ZipCheckOwnerTest {
    
   @testSetup
   public static void setupData() {
      TriggerMethodsTest.createTriggerSetting('AccountBefore', true, false, false, false, new String[]{'ZipCheckOwner','AccountJunctionMethods'});
      TriggerMethodsTest.createTriggerSetting('AccountAfter', false, true, false, false, new String[]{'ZipCheckOwner','AccountJunctionMethods'});
      TriggerMethodsTest.createTriggerSetting('ReferralAccountBefore', true, false, false, false, new String[]{'ZipCheckOwner'});
      TriggerMethodsTest.createTriggerSetting('ReferralContactBefore', true, false, false, false, new String[]{'ZipCheckOwner'});
      TriggerMethodsTest.saveSetupClasses();
      HoldOutExpirationMethodsTest.populateSetting();
      UserHelperTest.setupSalesOrgSetting();
      RecordTypeHelperTest.setupRecordType();
      AccountJunctionMethodsTest.populateSettings();
   } // setupData

   public static void resetTriggers() {
      ZipCheckOwner.accountIdsProcessedSet.clear();
      TriggerMethods.clearVariables();
      ZipCheckOwner.SKIP_TRIGGERS=false;
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=false;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=false;
   } // resetTriggers
    
   /* The number of records to process for a bulk trigger. */
   private static Integer bulkCount = 10;
   
   public static RecordType__c rtCoreRefAcct1 = null;
   public static RecordType__c rtCoreRefCtct1;
   public static RecordType__c rtHrsRefCtct1;
   public static RecordType__c rtPEOAcct1;
   public static RecordType__c rtCoreAcct1;
   public static RecordType__c rtCoreCtct1;
   
   public static HoldOut_ExpirationDates__c holdOutPAY;
   public static HoldOut_ExpirationDates__c holdOutHRS;
   public static HoldOut_ExpirationDates__c holdOutPAS;
      
   public static void setupCustomSettings() {
      // if they're already setup don't need to do anything else.
      RecordTypeHelperTest.setupRecordType();
      rtCoreRefAcct1 = RecordType__c.getInstance(RecordTypeHelper.CORE_REFERRAL_ACCOUNT);
      rtCoreRefCtct1 = RecordType__c.getInstance(RecordTypeHelper.CORE_REFERRAL_CONTACT);
      rtHrsRefCtct1 = RecordType__c.getInstance(RecordTypeHelper.HRS_REFERRAL_CONTACT);

      rtCoreAcct1 = RecordType__c.getInstance(RecordTypeHelper.CORE_ACCOUNT);
      rtCoreCtct1 = RecordType__c.getInstance(RecordTypeHelper.CORE_CONTACT);
             
      holdOutPAY = HoldOutExpirationMethodsTest.hoPAY;
      holdOutHRS = HoldOutExpirationMethodsTest.hoHRS;
      holdOutPAS = HoldOutExpirationMethodsTest.hoPAS;

   } // setupCustomSettings

   public static Account getAccount(Id idValue, Set<String> recordTypeIds) {
      List<Id> acctIds = new List<Id>{idValue};
      List<Account> accts = ZipCheckOwner.getAccounts(acctIds, recordTypeIds);
      // should always be one record returned.
      return accts.get(0);
   } // getAccount
   
   public static Map<Id,Account> getAccounts(Id[] acctIds, Set<String> recordTypeIds) {
      List<Account> accts = ZipCheckOwner.getAccounts(acctIds, recordTypeIds);
      Map<Id,Account> acctMap = new Map<Id,Account>();
      for (Account acct : accts) {
         acctMap.put(acct.Id,acct);
      } // for
      return acctMap;
   } // getAccounts
   
   public static User[] getSalesReps(Integer nbrReps, Id[] excludeIds) {
      excludeIds = (excludeIds != null ? excludeIds : new Id[]{});
      System.debug('getSalesReps nbrReps='+nbrReps+' excludeIds='+excludeIds);
      User[] users = [Select Id, Name 
                            ,HR_Person_Id__c
                            ,Sales_Org__c
                        from User 
                       where IsActive=true 
                         and Job_Name__c=:UserHelper.JOB_REP
                         and HR_Person_Id__c != null 
                         and Selling_Start_Date__c != null
                         and Id NOT IN :excludeIds
                        limit :nbrReps];
      return users;
   } // getSalesReps
   
   // the number of orgs that have users found
   public static Integer numOrgsWithUsers = 0;
   
   public static Zip_Segment__c[] segments = null;
   
   //public static Map<String,Zip_Segment__c> segmentByNameMap = new Map<String,Zip_Segment__c>();
   
   public static void setupSegments() {
      System.debug('setupSegments segments='+(segments != null ? segments.size() : -1));
      if (segments != null) {
         return;
      }
      // see if the segments already exist
      segments = ZipQueries.getAllSegments();
      System.debug('setupSegments segments='+segments.size());
       if (!segments.isEmpty()) {
          populateSegmentStaticVars();
          return;
       }
       // so the query can be performed again.
      ZipQueries.clearSegments();
      //UserHelperTest.setupSalesOrgSetting();
      // create zip segments
      segments = new Zip_Segment__c[]{};
      
      //ctctOwnerFldName, ctctHoldOutFldName, rfrlAcctOwnerFldName, rfrlAcctHoldOutFldName,rfrlCtctOwnerFldName, rfrlCtctHoldOutFldName
      //
      
      coreSeg1 = createSegment(UserHelper.SO_CORE, 0,99, '1','OwnerId', 'Hold_Out__c', 'Core Account Record Type',null
                              //,'OwnerId','Hold_Out__c','OwnerId','Hold_Out__c','OwnerId','Hold_Out__c');
                              ,'OwnerId','Hold_Out__c',null,null,null,null);
      //coreSeg1.RfrlAcctDefault__c = true;
      coreSeg1.LeadRecordTypeName__c = Label.RT_Core_Lead;
      
      coreSeg2 = createSegment(UserHelper.SO_CORE, 100,9999, '2','OwnerId', 'Hold_Out__c', 'Core Account Record Type',null
                              ,'OwnerId','Hold_Out__c',null,null,null,null);
      coreSeg2.LeadRecordTypeName__c = Label.RT_Core_Lead;
      coreSeg2.FallbackSegment__c=UserHelper.SO_CORE+'-'+coreSeg1.Name;
      
      mmsSeg1 = createSegment(UserHelper.SO_MMS, 0,99,'1','OwnerId', 'Hold_Out__c', 'MMS Account Record Type',null
                              ,'OwnerId','Hold_Out__c','MMS_Account_Owner__c',null,'MMS_Contact_Owner__c',null);
      mmsSeg1.RfrlAcctDefault__c = true;
      mmsSeg1.LeadRecordTypeName__c = Label.RT_MMS_Lead;
      mmsSeg2 = createSegment(UserHelper.SO_MMS, 100,9999,'2','OwnerId', 'Hold_Out__c', 'MMS Account Record Type',null
                              ,'OwnerId','Hold_Out__c',null,null,null,null);
      mmsSeg2.LeadRecordTypeName__c = Label.RT_MMS_Lead;
      mmsSeg2.FallbackSegment__c=UserHelper.SO_MMS+'-'+mmsSeg1.Name;
      
      hrsSeg1 = createSegment(UserHelper.SO_401, 0,99,'1','HRS_Account_Owner__c', 'HRS_Hold_Out__c', null,Label.AT_401K
                              ,'HRS_Contact_Owner__c',null,'HRS_Account_Owner__c',null,'HRS_Contact_Owner__c',null);
      hrsSeg1.RfrlAcctDefault__c = true;
      hrsSeg1.RfrlRecordTypes__c='Core Referral Source Record Type;MMS Referral Account Record Type;HRS Referral Source Record Type';
      hrsSeg1.LeadRecordTypeName__c = Label.RT_HRS_Lead;
       
      hrsSeg2 = createSegment(UserHelper.SO_401, 100,9999,'2','HRS_Account_Owner__c', 'HRS_Hold_Out__c', null,Label.AT_LGMKT_401K
                              ,'HRS_Contact_Owner__c',null,null,null,null,null);
      hrsSeg2.LeadRecordTypeName__c = Label.RT_HRS_Lead;
      
      pasSeg1 = createSegment(UserHelper.SO_PEO_ASO, 0,99,'1','Premier_PBS_Account_Owner__c', 'Premier_PBS_Hold_Out__c', null,Label.AT_PEO_ASO
                              ,'Premier_PBS_Contact_Owner__c',null,'Premier_PBS_Account_Owner__c',null,'Premier_PBS_Contact_Owner__c',null);
      pasSeg1.RfrlAcctDefault__c = true;
      pasSeg1.RfrlRecordTypes__c='Core Referral Source Record Type;MMS Referral Account Record Type;HRS Referral Source Record Type';
      pasSeg1.LeadRecordTypeName__c = Label.RT_PEO_ASO_Lead;
       
      pasSeg2 = createSegment(UserHelper.SO_PEO_ASO, 100,9999,'2','Premier_PBS_Account_Owner__c', 'Premier_PBS_Hold_Out__c', null,Label.AT_PEO_ASO
                              ,'Premier_PBS_Contact_Owner__c',null,null,null,null,null);
      pasSeg2.LeadRecordTypeName__c = Label.RT_PEO_ASO_Lead;
      
      peoSeg1 = createSegment(UserHelper.SO_PEO, 0, 9999,'1','OasisPEOAccountOwner__c', 'OasisPEOHoldOut__c','Core Account Record Type',Label.AT_PEO_ASO
                              ,'OasisPEOOwner__c',null,null,null,null,null);                              
      peoSeg1.LeadRecordTypeName__c = Label.RT_PEO_Lead;
      
      hnbSeg1 = createSegment(UserHelper.SO_HNB, 0,99,'1','HNBF_Account_Owner__c', 'HNBF_Hold_Out__c', null,Label.AT_HNBF
                              ,'HNBF_Contact_Owner__c',null,'HNBF_Account_Owner__c',null,'HNBF_Contact_Owner__c',null);
      hnbSeg1.RfrlAcctDefault__c = true;
      hnbSeg1.RfrlRecordTypes__c='Core Referral Source Record Type;MMS Referral Account Record Type;HRS Referral Source Record Type';
      hnbSeg1.LeadRecordTypeName__c = Label.RT_HNBF_Lead;
       
      hnbSeg2 = createSegment(UserHelper.SO_HNB, 100,9999,'2','HNBF_Account_Owner__c', 'HNBF_Hold_Out__c', null,Label.AT_HNBF
                              ,'HNBF_Contact_Owner__c',null,null,null,null,null);
      hnbSeg2.LeadRecordTypeName__c = Label.RT_HNBF_Lead;

      cpaSeg = createSegment('CPA', null,null, '',null, null, null,null
                              ,null,null,'OwnerId','Hold_Out__c','OwnerId','Hold_Out__c');
      cpaSeg.RfrlAcctDefault__c = true;
      cpaSeg.RfrlRecordTypes__c='Core Referral Source Record Type;MMS Referral Account Record Type';
      cpaSeg.ReferralSourceType__c='Accounting Firm;Strategic Accountant Firm';
      cpaSeg.FallbackSegment__c = coreSeg1.Sales_Org__c+'-'+coreSeg1.Name;
      cpaSeg.Sales_Org__c = coreSeg1.Sales_Org__c;
       
      finAdvSeg = createSegment('Financial Advisor', null,null, '',null, null, null,null
                              ,null,null,'OwnerId','Hold_Out__c','OwnerId','Hold_Out__c');
      finAdvSeg.RfrlAcctDefault__c = true;
      finAdvSeg.RfrlRecordTypes__c='HRS Referral Source Record Type';
      finAdvSeg.ReferralSourceType__c='Financial Services';
      finAdvSeg.FallbackSegment__c = hrsSeg1.Sales_Org__c+'-'+hrsSeg1.Name;
      finAdvSeg.Sales_Org__c = hrsSeg1.Sales_Org__c;

      intWhole = createSegment(UserHelper.SO_WHOLESALER, 0,999999,'1',null, null, null,Label.AT_INT_WHOLE
                              ,null,null,'Internal_Wholesaler_Account_Owner__c',null,'Internal_Wholesaler_Contact_Owner__c',null);
      intWhole.RfrlAcctDefault__c = true;
      intWhole.RfrlRecordTypes__c='Core Referral Source Record Type;MMS Referral Account Record Type;HRS Referral Source Record Type';
      intWhole.Name = UserHelper.WHOLESALER_INTERNAL;
      intWhole.FallbackSegment__c = hrsSeg1.Sales_Org__c+'-'+hrsSeg1.Name;

      System.debug('setupSegments before insert segments='+segments.size());
      insert segments;
      System.debug('setupSegments end of method segments='+segments.size());
   } // setupSegments
    
    public static void populateSegmentStaticVars() {
       Map<String,Zip_Segment__c> segMap = new Map<String,Zip_Segment__c>();
        for (Zip_Segment__c seg : segments) {
           segMap.put(seg.Name, seg);
        }
       System.debug('populateSegmentStaticVars segMap='+segMap.size());
       cpaSeg = segMap.get('CPA');
       finAdvSeg = segMap.get('Financial Advisor');
       coreSeg1 = segMap.get(UserHelper.SO_CORE+'1');
       coreSeg2 = segMap.get(UserHelper.SO_CORE+'2');
       mmsSeg1 = segMap.get(UserHelper.SO_MMS+'1');
       mmsSeg2 = segMap.get(UserHelper.SO_MMS+'2');
       hrsSeg1 = segMap.get(UserHelper.SO_401+'1');
       hrsSeg2 = segMap.get(UserHelper.SO_401+'2');
       pasSeg1 = segMap.get(UserHelper.SO_PEO_ASO+'1');
       pasSeg2 = segMap.get(UserHelper.SO_PEO_ASO+'2');
       peoSeg1 = segMap.get(UserHelper.SO_PEO+'1');

       hnbSeg1 = segMap.get(UserHelper.SO_HNB+'1');
       hnbSeg2 = segMap.get(UserHelper.SO_HNB+'2');
       intWhole = segMap.get(UserHelper.WHOLESALER_INTERNAL);
    } // populateSegmentStaticVars

   public static Zip_Segment__c cpaSeg = null;
   public static Zip_Segment__c finAdvSeg = null;
   
   public static Zip_Segment__c coreSeg1 = null;
   public static Zip_Segment__c coreSeg2 = null;

   public static Zip_Segment__c mmsSeg1 = null;
   public static Zip_Segment__c mmsSeg2 = null;
    
   public static Zip_Segment__c hrsSeg1 = null;
   public static Zip_Segment__c hrsSeg2 = null;

   public static Zip_Segment__c pasSeg1 = null;
   public static Zip_Segment__c pasSeg2 = null;
   public static Zip_Segment__c peoSeg1 = null;     //PEO Centric

   public static Zip_Segment__c hnbSeg1 = null;
   public static Zip_Segment__c hnbSeg2 = null;
   
   public static Zip_Segment__c intWhole = null;

   public static Zip_Segment__c createSegment(String salesOrg, Integer empsMin, Integer empsMax, String segNbr
                                   ,String ownerFieldName, String holdOutName, String recordTypeName, String roleName
                                   ,String ctctOwnerFldName, String ctctHoldOutFldName, String rfrlAcctOwnerFldName, String rfrlAcctHoldOutFldName
                                   ,String rfrlCtctOwnerFldName, String rfrlCtctHoldOutFldName) {
      Zip_Segment__c segment = new Zip_Segment__c(Name=salesOrg+segNbr,Sales_Org__c=salesOrg
                            ,Emps_Min__c=empsMin, Emps_Max__c=empsMax, JoinCriteria__c=(empsMin != null ? ZipCheckOwner.JOIN_EMPS : null)
                            ,AcctHoldOutFldName__c=holdOutName
                            ,AcctOwnerFldName__c=ownerFieldName
                            ,AccountRecordTypes__c=recordTypeName
                            ,TeamRole__c=roleName
                            ,CtctHoldOutFldName__c=ctctHoldOutFldName
                            ,CtctOwnerFldName__c=ctctOwnerFldName
                            ,RfrlAcctHoldOutFldName__c=rfrlAcctHoldOutFldName
                            ,RfrlAcctOwnerFldName__c=rfrlAcctOwnerFldName
                            ,RfrlCtctHoldOutFldName__c=rfrlCtctHoldOutFldName
                            ,RfrlCtctOwnerFldName__c=rfrlCtctOwnerFldName
                            );
      segments.add(segment);
      return segment;
   } // createSegment

   /** get a collection of Zas, all with multiple tiers, for each sales org
    */
   public static Map<String,List<Zip_Assignment__c>> getZaMapList(String zipCode,Id[] excludeUserIds) {
      setupSegments();
      
      numOrgsWithUsers = 0;
      List<Zip_Assignment__c> allZas = new List<Zip_Assignment__c>();
      //User[] users = getSalesReps(((UserHelper.DIVISION_LIST.size()*2)+2), excludeUserIds);
      User[] users = getSalesReps((segments.size()+2), excludeUserIds);
      // a map of the zip codes by sales org
      Map<String,List<Zip_Assignment__c>> zaMapList = new Map<String,List<Zip_Assignment__c>>();
      //for (String salesOrg : UserHelper.DIVISION_LIST) {
      for (Zip_Segment__c zs : segments) {
         List<Zip_Assignment__c> zaList = zaMapList.get(zs.Sales_Org__c);
         if (zaList == null) {
            zaList = new List<Zip_Assignment__c>();
            zaMapList.put(zs.Sales_Org__c, zaList);
            numOrgsWithUsers++;
         }
         Zip_Assignment__c za = createZa(zipCode, users[allZas.size()], zs.Sales_Org__c, zs.Name, zs.Id, null, excludeUserIds, zaList);
         allZas.add(za);
 
      } // for (String salesOrg
      
      // create wholesaler tiers
      List<Zip_Assignment__c> zaList = new List<Zip_Assignment__c>();

      // create internal and external wholesalers
      createZa(zipCode, users[allZas.size()], UserHelper.SO_WHOLESALER, UserHelper.WHOLESALER_INTERNAL, null, null, excludeUserIds, zaList);
      //createZa(zipCode, users[allZas.size()+1], UserHelper.SO_WHOLESALER, UserHelper.WHOLESALER_EXTERNAL, null, null, excludeUserIds, zaList);
      zaMapList.put(UserHelper.SO_WHOLESALER,zaList);
      allZas.addAll(zaList);
      
      insert allZas;
      return zaMapList;
   } // getZas

   public static Zip_Assignment__c createZa(String zipCode, User u, Integer min, Integer max, String salesOrg, String segmentName, Id zipSegmentId, Id[] userIds, List<Zip_Assignment__c> zaList) {
      return createZa(zipCode, u, salesOrg, segmentName, zipSegmentId, null, userIds, zaList);
   }
   
   public static Zip_Assignment__c createZa(String zipCode, User u, Integer min, Integer max, String salesOrg, String segmentName, Id zipSegmentId, ZipTerritory__c zipTerritory, Id[] userIds, List<Zip_Assignment__c> zaList) {
      return createZa(zipCode, u, salesOrg, segmentName, zipSegmentId, zipTerritory, userIds, zaList);
   }

   public static Zip_Assignment__c createZa(String zipCode, User u, String salesOrg, String segmentName, Id zipSegmentId, ZipTerritory__c zipTerritory, Id[] userIds, List<Zip_Assignment__c> zaList) {
      System.debug('createZa zipCode='+zipCode+' salesOrg='+salesOrg+' segmentName='+segmentName+' u='+(u != null ? u.Id+': '+u.Name : 'No User'));
      Zip_Assignment__c za = new Zip_Assignment__c(Name=zipCode,HR_Person_Id__c=(u != null ? u.HR_Person_Id__c : null)
                                           ,User__c=(u != null ? u.Id : null), User__r=u
                                           ,Sales_Org__c=salesOrg
                                           ,Segment_Name__c=segmentName, Zip_Segment__c=zipSegmentId
                                           ,ZipTerritory__c=(zipTerritory != null ? zipTerritory.Id : null)
                                           ,District__c=(zipTerritory != null ? zipTerritory.District__c : null));
      zaList.add(za);
      if (userIds != null) {
         userIds.add(u.Id);
      }
      return za;
   } // createZa
   
   public static ZipTerritory__c terrCore1 = null;
   public static ZipTerritory__c terrCore2 = null;
   public static ZipTerritory__c terrMms1 = null;
   public static ZipTerritory__c terrMms2 = null;
   public static ZipTerritory__c terrHrs1 = null;
   public static ZipTerritory__c terrHrs2 = null;
   public static ZipTerritory__c terrPeo1 = null;
   public static ZipTerritory__c terrPeo2 = null;
   public static ZipTerritory__c terrPeoC = null;
   public static ZipTerritory__c terrHnb1 = null;
   public static ZipTerritory__c terrHnb2 = null;
   public static ZipTerritory__c terrWhole1 = null;
   public static ZipTerritory__c terrCPA = null;
   public static ZipTerritory__c terrFinAdv = null;

   // all of the zip assignments - they're not saved immediately after creation
   public static Zip_Assignment__c[] zas = new Zip_Assignment__c[]{};
   public static Zip_Assignment__c zaCore1Seg1 = null;
   public static Zip_Assignment__c zaCore1Seg2 = null;
   public static Zip_Assignment__c zaCore2Seg1 = null;
   public static Zip_Assignment__c zaCore3Seg1 = null;
   public static Zip_Assignment__c zaMMS1Seg1 = null;
   public static Zip_Assignment__c zaMMS1Seg2 = null;
   public static Zip_Assignment__c zaHRS1Seg1 = null;
   public static Zip_Assignment__c zaHRS1Seg2 = null;
   public static Zip_Assignment__c zaPEO1Seg1 = null;
   public static Zip_Assignment__c zaPEO1Seg2 = null;
   public static Zip_Assignment__c zaPEO1SegC = null;
   public static Zip_Assignment__c zaHNB1Seg1 = null;
   public static Zip_Assignment__c zaHNB1Seg2 = null;
   public static Zip_Assignment__c zaWholeInt = null;
   public static Zip_Assignment__c zaCPA = null;
   public static Zip_Assignment__c zaFinAdv = null;

   public static User uCore = null;
   public static User uCore2 = null;
   public static User uHrsInt = null;
   public static User uHrsExt = null;
    
   // the users used to create the territories
   public static Set<Id> usedUserIdSet = new Set<Id>();
   
   public static void setupZipsAndSegments(Boolean saveZips) {
      ZipCheckOwnerTest.setupSegments();

      // see if this has already run
      Integer cnt = [Select count() from ZipTerritory__c where Name like 'terr%'];
      // if any are returned then this was already called. But we'll still setup the static variables.
      if (cnt > 0) {
         setupZipAndTerrStatics();
      }
      // so the trigger fires.
      User runningUser = UserHelper.getRunningUser();
      ProcessNameMap__c pnm = UserHelperTest.setupProcessName(UserHelper.PREFIX_SFDC,runningUser.Name);
      //User[] allUsers = new User[]{runningUser};

      // select test users
      User[] users = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 16];
      Map<Id,User> userMap = new Map<Id,User>(users);
      usedUserIdSet = userMap.keySet();
       
      uCore = users[0];
      uCore2 = users[1];
      User uMms = users[2];
      User uMms2 = users[3];
      User uHrs = users[4]; 
      User uHrs2 = users[5]; 
      uHrsInt = users[6];
      uHrsExt = users[7];
      User uPeo = users[8];
      User uPeo2 = users[9];
      User uPeoC = users[10];
      User uHnb = users[11];
      User uHnb2 = users[12];
      User uCPA = users[13];
      User uFinAdv = users[14];

      // make sure there are no change records
      System.assertEquals(0,[Select count() from Zip_Assignment_Change__c]);
      
      Org_Unit__c distCore = new Org_Unit__c(Name='1', Org_Type__c='District', Sales_Org__c=UserHelper.SO_CORE);
      Org_Unit__c distMms = new Org_Unit__c(Name='1', Org_Type__c='District', Sales_Org__c=UserHelper.SO_MMS);
      Org_Unit__c distHrs = new Org_Unit__c(Name='1', Org_Type__c='District', Sales_Org__c=UserHelper.SO_401);
      Org_Unit__c distPeo = new Org_Unit__c(Name='1', Org_Type__c='District', Sales_Org__c=UserHelper.SO_PEO);
      Org_Unit__c distPas = new Org_Unit__c(Name='1', Org_Type__c='District', Sales_Org__c=UserHelper.SO_PEO_ASO);
      Org_Unit__c distHnbf = new Org_Unit__c(Name='1', Org_Type__c='District', Sales_Org__c=UserHelper.SO_HNB);
      Org_Unit__c[] districts = new Org_Unit__c[]{distCore,distMms,distHrs,distPas,distPeo,distHnbf};
      insert districts;
      
      
      terrCore1 = new ZipTerritory__c(Name='terrCore1',District__c=distCore.Id, TerritoryRep__c=uCore.Id,Zip_Segment__c=coreSeg1.Id);
      terrCore2 = new ZipTerritory__c(Name='terrCore2',District__c=distCore.Id, TerritoryRep__c=uCore2.Id,Zip_Segment__c=coreSeg1.Id);
      terrMms1 = new ZipTerritory__c(Name='terrMms1',District__c=distMms.Id, TerritoryRep__c=uMms.Id,Zip_Segment__c=mmsSeg1.Id);
      terrMms2 = new ZipTerritory__c(Name='terrMms2',District__c=distMms.Id, TerritoryRep__c=uMms2.Id,Zip_Segment__c=mmsSeg2.Id);
      terrHrs1 = new ZipTerritory__c(Name='terrHrs1',District__c=distHrs.Id, TerritoryRep__c=uHrs.Id,Zip_Segment__c=hrsSeg1.Id);
      terrHrs2 = new ZipTerritory__c(Name='terrHrs2',District__c=distHrs.Id, TerritoryRep__c=uHrs2.Id,Zip_Segment__c=hrsSeg2.Id);
      terrPeo1 = new ZipTerritory__c(Name='terrPeo1',District__c=distPas.Id, TerritoryRep__c=uPeo.Id,Zip_Segment__c=pasSeg1.Id);
      terrPeo2 = new ZipTerritory__c(Name='terrPeo2',District__c=distPas.Id, TerritoryRep__c=uPeo2.Id,Zip_Segment__c=pasSeg2.Id);
      terrPeoC = new ZipTerritory__c(Name='terrPeoC',District__c=distPeo.Id, TerritoryRep__c=uPeoC.Id,Zip_Segment__c=peoSeg1.Id);      
      terrHnb1 = new ZipTerritory__c(Name='terrHnb1',District__c=distHnbf.Id, TerritoryRep__c=uHnb.Id,Zip_Segment__c=hnbSeg1.Id);
      terrHnb2 = new ZipTerritory__c(Name='terrHnb2',District__c=distHnbf.Id, TerritoryRep__c=uHnb2.Id,Zip_Segment__c=hnbSeg2.Id);
      terrWhole1 = new ZipTerritory__c(Name='terrWhole1',District__c=distHrs.Id, TerritoryRep__c=uHrsInt.Id,Zip_Segment__c=intWhole.Id);
      terrCPA = new ZipTerritory__c(Name='terrCPA',District__c=distCore.Id, TerritoryRep__c=uCPA.Id,Zip_Segment__c=cpaSeg.Id);
      terrFinAdv = new ZipTerritory__c(Name='terrFinAdv',District__c=distHrs.Id, TerritoryRep__c=uFinAdv.Id,Zip_Segment__c=finAdvSeg.Id);
      ZipTerritory__c[] territories = new ZipTerritory__c[]{terrCore1,terrCore2,terrMms1,terrMms2
                                                           ,terrHrs1,terrHrs2,terrPeo1,terrPeo2,terrPeoC
                                                           ,terrHnb1,terrHnb2,terrWhole1,terrCPA,terrFinAdv};
      insert territories;
      
      // create Zip Assignment records
      zaCore1Seg1 = createZa('14514', uCore, coreSeg1.Sales_Org__c, coreSeg1.Name, coreSeg1.Id, terrCore1, null, zas);
      zaCore1Seg2 = createZa('14514', uCore2, coreSeg2.Sales_Org__c, coreSeg2.Name, coreSeg2.Id, terrCore2, null, zas);
      zaCore2Seg1 = createZa('14515', uCore, coreSeg1.Sales_Org__c, coreSeg1.Name, coreSeg1.Id, terrCore1, null, zas);
      zaCore3Seg1 = createZa('14516', uCore, coreSeg1.Sales_Org__c, coreSeg1.Name, coreSeg1.Id, terrCore1, null, zas);
      zaMMS1Seg1 = createZa('14514', uMms, mmsSeg1.Sales_Org__c, mmsSeg1.Name, mmsSeg1.Id, terrMms1, null, zas);
      zaMMS1Seg2 = createZa('14514', uMms2, mmsSeg2.Sales_Org__c, mmsSeg2.Name, mmsSeg2.Id, terrMms2, null, zas);
      zaHRS1Seg1 = createZa('14514', uHrs, hrsSeg1.Sales_Org__c, hrsSeg1.Name, hrsSeg1.Id, terrHrs1, null, zas);
      zaHRS1Seg2 = createZa('14514', uHrs2, hrsSeg2.Sales_Org__c, hrsSeg2.Name, hrsSeg2.Id, terrHrs2, null, zas);
      zaPEO1Seg1 = createZa('14514', uPeo, pasSeg1.Sales_Org__c, pasSeg1.Name, pasSeg1.Id, terrPeo1, null, zas);
      zaPEO1Seg2 = createZa('14514', uPeo2, pasSeg2.Sales_Org__c, pasSeg2.Name, pasSeg2.Id, terrPeo2, null, zas);
      zaPEO1SegC = createZa('14425', uPeoC, peoSeg1.Sales_Org__c, peoSeg1.Name, peoSeg1.Id, terrPeoC, null, zas);
      zaHNB1Seg1 = createZa('14514', uHnb, hnbSeg1.Sales_Org__c, hnbSeg1.Name, hnbSeg1.Id, terrHnb1, null, zas);
      zaHNB1Seg2 = createZa('14514', uHnb2, hnbSeg2.Sales_Org__c, hnbSeg2.Name, hnbSeg2.Id, terrHnb2, null, zas);
                                                   
      zaWholeInt = createZa('14514', uHrsInt, UserHelper.SO_WHOLESALER, intWhole.Name, intWhole.Id, terrWhole1, null, zas);
      zaCPA = createZa('14514', uCPA, cpaSeg.Sales_Org__c, cpaSeg.Name, cpaSeg.Id, terrCPA, null, zas);
      zaFinAdv = createZa('14514', uFinAdv, finAdvSeg.Sales_Org__c, finAdvSeg.Name, finAdvSeg.Id, terrFinAdv, null, zas);
      
      if (saveZips) {
         insert zas;
      }
   } // setupZipsAndSegments

   public static void setupZipAndTerrStatics() {
      System.debug('setupZipAndTerrStatics');
      setupSegments();
      ZipTerritory__c[] terrs = [Select Id, Name
                                        ,CheckZipUser__c, District__c, District_Lockout__c
                                        ,OverrideAssistant__c, OverrideManager__c
                                        ,Rep_Name__c, Sales_Org__c, TerritoryContact__c
                                        ,Territory_Nbr__c, TerritoryRep__c, Zip_Segment__c
                                    From ZipTerritory__c];
      Map<String,ZipTerritory__c> terrMap = new Map<String,ZipTerritory__c>();
      for (ZipTerritory__c terr : terrs) {
         terrMap.put(terr.Name,terr);
      }
      terrCore1 = terrMap.get('terrCore1');
      terrCore2 = terrMap.get('terrCore2');
      terrMms1 = terrMap.get('terrMms1');
      terrMms2 = terrMap.get('terrMms2');
      terrHrs1 = terrMap.get('terrHrs1');
      terrHrs2 = terrMap.get('terrHrs2');
      terrPeo1 = terrMap.get('terrPeo1');
      terrPeo2 = terrMap.get('terrPeo2');
      terrPeoC = terrMap.get('terrPeoC');      
      terrHnb1 = terrMap.get('terrHnb1');
      terrHnb2 = terrMap.get('terrHnb2');
      terrWhole1 = terrMap.get('terrWhole1');
      terrCPA = terrMap.get('terrCPA');
      terrFinAdv = terrMap.get('terrFinAdv');

      setZipStatic();

   } // setupZipAndTerrStatics
    
    public static void setZipStatic() {
      Zip_Assignment__c[] zas = [Select Id, Name, District__c, DistrictNbr__c, EvaluateSkipJoin__c, HR_Person_Id__c
                                       ,QueryKey__c, Rep_Name__c, Sales_Org__c, Segment_Name__c, SkipJoinCriteria__c
                                       ,ZipTerritory__c, UseForReferralSource__c, User__c, Zip_Code_Information__c
                                       ,Zip_Segment__c
                                       ,User__r.Id, User__r.Name, User__r.Sales_Org__c
                                  From Zip_Assignment__c]; 
      Map<String,Zip_Assignment__c> zaMap = new Map<String,Zip_Assignment__c>();
      for (Zip_Assignment__c za : zas) {
         String key=za.Segment_Name__c+za.Name;
         System.debug('setZipStatic key='+key);
         zaMap.put(za.Segment_Name__c+za.Name, za);
      }
      zaCore1Seg1 = zaMap.get(coreSeg1.Name+'14514');
      zaCore1Seg2 = zaMap.get(coreSeg2.Name+'14514');
      zaCore2Seg1 = zaMap.get(coreSeg1.Name+'14515');
      zaCore3Seg1 = zaMap.get(coreSeg1.Name+'14516');
      zaMMS1Seg1 = zaMap.get(mmsSeg1.Name+'14514');
      zaMMS1Seg2 = zaMap.get(mmsSeg2.Name+'14514');
      zaHRS1Seg1 = zaMap.get(hrsSeg1.Name+'14514');
      zaHRS1Seg2 = zaMap.get(hrsSeg2.Name+'14514');
      zaPEO1Seg1 = zaMap.get(pasSeg1.Name+'14514');
      zaPEO1Seg2 = zaMap.get(pasSeg2.Name+'14514');
      zaPEO1SegC = zaMap.get(peoSeg1.Name+'14425');
      zaHNB1Seg1 = zaMap.get(hnbSeg1.Name+'14514');
      zaHNB1Seg2 = zaMap.get(hnbSeg2.Name+'14514');
      System.debug('setZipStatic intWhole='+intWhole);
      zaWholeInt = zaMap.get(intWhole.Name+'14514');
      zaCPA = zaMap.get(cpaSeg.Name+'14514');
      zaFinAdv = zaMap.get(finAdvSeg.Name+'14514');
    } // setZipStatic
    
    public static Zip_Assignment__c getZipBySegment(Zip_Assignment__c[] zas, Id segmentId) {
      Zip_Assignment__c retZa = null;
      for (Zip_Assignment__c za : zas) {
         if (za.Zip_Segment__c == segmentId) {
             retZa = za;
             break;
         }
      }
      return retZa; 
   } // getZipBySegment

   static testmethod void testAccount1() {
      // so the trigger will fire for System Administrators
      ZipCheckOwner.EXCLUDE_PROFILE_NAME_LIST = new String[]{'System Administrator API–Relational Junction'};
      System.debug('Start testAcount1');
      Map<String,Schema.RecordTypeInfo> byId = new Map<String,Schema.RecordTypeInfo>();
      Map<String,Schema.RecordTypeInfo> byName = new Map<String,Schema.RecordTypeInfo>();
      
      // add two record types that the process shouldn't modify
      String[] recordTypeNames = new String[]{'System Administration Account','Admin'};
      recordTypeNames.addAll(ZipCheckOwner.RECORDTYPE_NAMES);
      RecordTypeHelper.getRecordTypesMap(ZipCheckOwner.OBJECT_NAMES,recordTypeNames,byId,byName);
      
      Schema.RecordTypeInfo rtCore = byName.get(RecordTypeHelper.CORE_ACCOUNT);
      Schema.RecordTypeInfo rtMms = byName.get(RecordTypeHelper.MMS_ACCOUNT);
      Schema.RecordTypeInfo rtCtctCore = byName.get(RecordTypeHelper.CORE_CONTACT);
      Schema.RecordTypeInfo rtCtctMms = byName.get(RecordTypeHelper.MMS_CONTACT);

      Schema.RecordTypeInfo acctTestRt = byName.get('System Administration Account');
      Schema.RecordTypeInfo ctctTestRt = byName.get('Admin');

      //Profile p = [select id from profile where name='System Administrator'];
      User user1 = UserHelper.getRunningUser();
      
      System.debug('user1='+user1.Id);
      // store the userIds used to create the zip codes
      Id[] excludeUserIds = new Id[]{};
      //String zip1 = '12345';
      //Map<String,List<Zip_Assignment__c>> zaMapList1 = getZaMapList(zip1,excludeUserIds);
      //String zip2 = '12346';
      //Map<String,List<Zip_Assignment__c>> zaMapList2 = getZaMapList(zip2,excludeUserIds);
      setupZipsAndSegments(true);
      // to retrieve the user information with the zip
      setZipStatic();
      String zip1=zaCore1Seg1.Name;
      String zip2=zaCore2Seg1.Name;
      // select a user not already assigned a zip code to run as
      //User[] users = getSalesReps(1, excludeUserIds);
      //User testUser = users.get(0);
      
      //***************************************
      System.debug('Check that nothing changes with unrecognized Record Type user1='+user1.Name);
      // check to make sure nothing changes for different record type

      System.runAs(user1) {
         Account acct = new Account(name='Test d1_a',ShippingPostalCode=zip1,RecordTypeId=acctTestRt.getRecordTypeId());
         insert acct;
         // select and make sure record type is the same
         Set<String> recordTypeIds = new Set<String>{acctTestRt.getRecordTypeId()};
         acct = getAccount(acct.Id,recordTypeIds);
         System.assertEquals(user1.Id, acct.OwnerId);
         
         // change zip code and make sure doesn't change
         acct.ShippingPostalCode=zip2;
         TriggerMethods.clearVariables();
         update acct;
         acct = getAccount(acct.Id,recordTypeIds);
         // the owner should not change because the record type is not one of the specified types
         System.assertEquals(user1.Id, acct.OwnerId);

         //*************************************
         // core owner should be first user - no emp count
         //User core1 = zaMapList1.get(UserHelper.SO_CORE).get(0).User__r;
         //User core2 = zaMapList2.get(UserHelper.SO_CORE).get(0).User__r;
         User core1 = zaCore1Seg1.User__r;
         User core2 = zaCore2Seg1.User__r;
         
         System.debug('test no ShippingPostalCode, BillingPostalCode changes');
         acct = new Account(name='Test d1_b',ShippingPostalCode=null, BillingPostalCode=zip1,RecordTypeId=rtCore.getRecordTypeId());
         insert acct;
         acct = getAccount(acct.Id,byId.keySet());
         System.assertEquals(core1.Id,acct.OwnerId);
         acct.BillingPostalCode=zip2;
         System.debug('updating record acct');
         ZipCheckOwner.accountIdsProcessedSet.clear();
         TriggerMethods.clearVariables();
         update acct;
         acct = getAccount(acct.Id,byId.keySet());
         // the owner should change based on the BillingPostalCode
         System.assertEquals(core2.Id,acct.OwnerId);

         //***************************************
         System.debug('testing hold out flag is set - ownership should not change');
         acct = new Account(name='Test d1_c',ShippingPostalCode=zip1,RecordTypeId=rtCore.getRecordTypeId(),Hold_Out__c=true,Permanent_Hold_Out_Description__c='Testing Holdout');
         TriggerMethods.clearVariables();
         insert acct;
         acct = getAccount(acct.Id,byId.keySet());
         System.assertEquals(user1.Id,acct.OwnerId);
         acct.ShippingPostalCode=zip2;
         ZipCheckOwner.accountIdsProcessedSet.clear();
         TriggerMethods.clearVariables();
         update acct;
         acct = getAccount(acct.Id,byId.keySet());
         // the owner should not change because of the hold out flag
         System.assertEquals(acct.OwnerId,user1.Id);
         // hold out flag changes - should trigger ownership change
         acct.Hold_Out__c = false;
         acct.Permanent_Hold_Out_Description__c = null;
         ZipCheckOwner.accountIdsProcessedSet.clear();
         TriggerMethods.clearVariables();
         update acct;
         acct = getAccount(acct.Id,byId.keySet());
         // the owner should have changed when the hold out flag was set.
         System.assertEquals(acct.OwnerId,core2.Id);

      } // System.runAs(testUser)
      
   } // testAccount1

   static testMethod void testAccountTeams() {
      // get a user to run as
      User u = [Select Id, Name, HR_Person_Id__c from User where isActive=true and DelegatedApproverId = null and id != :UserInfo.getUserId() and Profile.Name='System Administrator' limit 1];
      // get test users
      User[] users = [Select Id, Name, FirstName, LastName, HR_Person_Id__c from User where UserRoleId != null and ProfileId != null and isActive=true and DelegatedApproverId = null
                         and Job_Name__c=:UserHelper.JOB_REP 
                         and HR_Person_Id__c != null
                         and id != :UserInfo.getUserId() and id != :u.Id and Sales_Org__c = :UserHelper.SO_CORE limit 6];
      User u1 = users[0];
      User u2 = users[1];
      User u3 = users[2];
      User u4 = users[3];
      User u5 = users[4];
      User u6 = users[5];
      
      Schema.RecordTypeInfo ctctSArt = RecordTypeHelper.getRecordType('Paychex Employee', ObjectHelper.OBJECT_CONTACT);
        
      Account acct1 = ContactFormatPaychexEmps.getParentAcct();
        
      // create Contact records for the test users
      Contact c1 = new Contact(AccountId=acct1.Id,FirstName=u1.FirstName,LastName=u1.LastName,HR_Person_Id__c=u1.HR_Person_Id__c, RecordTypeId=ctctSArt.getRecordTypeId(), User_Lookup__c=u1.Id);
      Contact c2 = new Contact(AccountId=acct1.Id,FirstName=u2.FirstName,LastName=u2.LastName,HR_Person_Id__c=u2.HR_Person_Id__c, RecordTypeId=ctctSArt.getRecordTypeId(), User_Lookup__c=u2.Id);
      Contact c3 = new Contact(AccountId=acct1.Id,FirstName=u3.FirstName,LastName=u3.LastName,HR_Person_Id__c=u3.HR_Person_Id__c, RecordTypeId=ctctSArt.getRecordTypeId(), User_Lookup__c=u3.Id);
      Contact[] ctcts = new Contact[]{c1,c2,c3};
      insert ctcts;

      System.runAs(u) {
         Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
         Account a1 = new Account(Name='Test Acct1'
                                 ,RecordTypeId=rt.getRecordTypeId()
                                 ,HRS_Account_Owner__c=u4.Id
                                 ,Premier_PBS_Account_Owner__c=u5.Id
                                 ,HNBF_Account_Owner__c=u6.Id
                                 ,HR_Generalist__c=c1.Id
                                 ,HR_Manager__c=c2.Id);
         System.debug('inserting account');
         insert a1;
         Account upa1 = [Select Id, Name, HRS_Account_Owner__r.Id, Premier_PBS_Account_Owner__r.Id,
                            HNBF_Account_Owner__r.Id, HR_Generalist__r.Id, HR_Manager__r.Id from Account where Id = :a1.Id];
         System.assertEquals(u4.Id,upa1.HRS_Account_Owner__r.Id);                            
         System.assertEquals(u5.Id,upa1.Premier_PBS_Account_Owner__r.Id);
         System.assertEquals(u6.Id,upa1.HNBF_Account_Owner__r.Id);

         // verify AccountTeamMembers were created
         AccountTeamMember[] atms = [Select Id, AccountId, UserId, TeamMemberRole from AccountTeamMember where AccountId=:a1.Id];
         System.assertEquals(2,atms.size());
         // verify each one is present
         Integer nbrVerified = 0;
         for (AccountTeamMember atm : atms) {
            if ((atm.TeamMemberRole==ZipCheckOwner.AT_HRG && atm.UserId==u1.Id) 
                || (atm.TeamMemberRole==ZipCheckOwner.AT_HRM && atm.UserId==u2.Id)) {
               nbrVerified++;
            }
         } // for
         System.assertEquals(2,nbrVerified);
         
         // change one
         a1.HR_Generalist__c=c3.Id;
         TriggerMethods.clearVariables();
         ZipCheckOwner.accountIdsProcessedSet.clear();
         update a1;
         // make sure there's still 2
         //System.assertEquals(2,[Select count() from AccountTeamMember where AccountId=:a1.Id]);
         atms = [Select Id, AccountId, UserId, TeamMemberRole from AccountTeamMember where AccountId=:a1.Id];
         System.assertEquals(2,atms.size());
         // verify each one is present
         nbrVerified = 0;
         for (AccountTeamMember atm : atms) {
            if ((atm.TeamMemberRole==ZipCheckOwner.AT_HRG && atm.UserId==u3.Id) 
                || (atm.TeamMemberRole==ZipCheckOwner.AT_HRM && atm.UserId==u2.Id)) {
               nbrVerified++;
            }
         } // for
         System.assertEquals(2,nbrVerified);
         
         // remove one
         a1.HR_Manager__c=null;
         TriggerMethods.clearVariables();
         update a1;
         // should only be 1 now.
         atms = [Select Id, AccountId, UserId, TeamMemberRole from AccountTeamMember where AccountId=:a1.Id];
         System.assertEquals(1,atms.size());
         // verify each one is present
         nbrVerified = 0;
         for (AccountTeamMember atm : atms) {
            if ((atm.TeamMemberRole==ZipCheckOwner.AT_HRG && atm.UserId==u3.Id) 
                || (atm.TeamMemberRole==ZipCheckOwner.AT_HRM && atm.UserId==u2.Id)) {
               nbrVerified++;
            }
         } // for
         System.assertEquals(1,nbrVerified);
      } // System.runAs       
   } // testAccountTeams

   static testMethod void testAccountTeamsWithZip() {
      setupZipsAndSegments(true);
      
      // force the seg1 hrs team member to be set even though it doesn't meet the criteria
      // set the join criteria for the hrs segments

      hrsSeg1.JoinCriteria__c = ZipCheckOwner.JOIN_EMPS;
      hrsSeg1.AlwaysAssignTeamMember__c=true;
      hrsSeg2.JoinCriteria__c = ZipCheckOwner.JOIN_EMPS;
      Zip_Segment__c[] segsToUpdate = new Zip_Segment__c[]{hrsSeg1,hrsSeg2};
      update segsToUpdate;
      
      Account acct1 = new Account(Name='Test Acct', NumberOfEmployees=150, ShippingPostalCode=zaCore1Seg1.Name);
      
      User sfdcData = [Select Id, Name, Email from User where Name=:UserHelper.SFDC_DATA and IsActive=true limit 1];
      System.runAs(sfdcData) {
         insert acct1;
      }

      AccountTeamMember[] atms = [Select Id, TeamMemberRole, UserId from AccountTeamMember where AccountId=:acct1.Id];

      System.debug('testAccountTeamsWithZip atms='+atms);
      
      //System.assertEquals(4,atms.size());
      Set<String> roleSet = new Set<String>{ZipCheckOwner.AT_401K,ZipCheckOwner.AT_LGMKT_401K,ZipCheckOwner.AT_PEO_ASO,ZipCheckOwner.AT_HNBF};
      Integer nbrFound = 0;
      for (AccountTeamMember atm : atms) {
         if (roleSet.remove(atm.TeamMemberRole)) {
            nbrFound++;
         }
      }
      System.assertEquals(true,nbrFound>=3);
      
   } // testAccountTeamsWithZip

   static testMethod void testCheckContactRecordType() {
      setupCustomSettings();
      
      Map<String,Schema.RecordTypeInfo> byNameMap = new Map<String,Schema.RecordTypeInfo>();
      RecordTypeHelper.getRecordTypesMap(new String[]{ObjectHelper.OBJECT_REF_ACCOUNT,ObjectHelper.OBJECT_REF_CONTACT}, null, null, byNameMap);
      
      Schema.RecordTypeInfo acctRtCore = byNameMap.get(RecordTypeHelper.CORE_REFERRAL_ACCOUNT);
      Schema.RecordTypeInfo ctctRtCore = byNameMap.get(RecordTypeHelper.CORE_REFERRAL_CONTACT);

      Schema.RecordTypeInfo acctRtHrs = byNameMap.get(RecordTypeHelper.HRS_REFERRAL_ACCOUNT);
      Schema.RecordTypeInfo ctctRtHrs = byNameMap.get(RecordTypeHelper.HRS_REFERRAL_CONTACT);
      
      Referral_Account__c refAcct = new Referral_Account__c(Name='Test Account', RecordTypeId=acctRtCore.getRecordTypeId());
      Referral_Contact__c refCtct = new Referral_Contact__c(Name='Test Contact', RecordTypeId=ctctRtHrs.getRecordTypeId());
      
      insert refAcct;
      refCtct.Referral_Account__c = refAcct.Id;
      insert refCtct;
      
      refAcct = [Select Id, Name, RecordTypeId, RecordType.Id, RecordType.Name from Referral_Account__c where id=:refAcct.Id];
      refCtct = [Select Id, Name, RecordTypeId, RecordType.Id, RecordType.Name from Referral_Contact__c where Id=:refCtct.Id];
      
      System.assertEquals(true,ZipCheckOwner.checkContactRecordType(refAcct, refCtct));
      System.assertEquals(ctctRtCore.getRecordTypeId(), refCtct.RecordTypeId);
      
      update refCtct;
      refCtct = [Select Id, Name, RecordTypeId, RecordType.Id, RecordType.Name from Referral_Contact__c where Id=:refCtct.Id];
      
      System.assertEquals(false,ZipCheckOwner.checkContactRecordType(refAcct, refCtct));
      System.assertEquals(ctctRtCore.getRecordTypeId(), refCtct.RecordTypeId);
      
      refAcct.RecordTypeId = acctRtHrs.getRecordTypeId();
      System.assertEquals(false,ZipCheckOwner.checkContactRecordType(refAcct, refCtct));
      System.assertEquals(ctctRtCore.getRecordTypeId(), refCtct.RecordTypeId);
      
      
   } // testCheckContactRecordType

   static testMethod void testCheckAcctHoldOuts() {
      setupCustomSettings();
      Account acct = new Account(Name='Test 1');
      System.debug('testCheckAcctHoldOuts Test 1');
      System.assertEquals(false,ZipCheckOwner.checkAcctHoldOuts(acct,null,null,null));
      
      acct.Hold_Out__c=true;
      acct.Hold_Out_Expiration__c = Date.today().addDays(5);
      acct.Permanent_Hold_Out_Description__c = 'Just Because';
      acct.HRS_Hold_Out__c=true;
      acct.HRS_Hold_Out_Expiration__c = Date.today().addDays(5);
      acct.HRS_Permanent_Hold_Out_Description__c = 'Just Because';
      acct.Premier_PBS_Hold_Out__c=true;
      acct.Premier_PBS_Hold_Out_Expiration__c = Date.today().addDays(5);
      acct.PEO_ASO_Permanent_Hold_Out_Description__c = 'Just Because';
      System.debug('testCheckAcctHoldOuts Test 2');
      System.assertEquals(false,ZipCheckOwner.checkAcctHoldOuts(acct,null,null,null));
      
      acct.Hold_Out_Expiration__c = Date.today().addDays(-5);
      System.debug('testCheckAcctHoldOuts Test 3');
      System.assertEquals(true,ZipCheckOwner.checkAcctHoldOuts(acct,null,null,null));
      System.assertEquals(false,acct.Hold_Out__c);
      System.assertEquals(null,acct.Hold_Out_Expiration__c);
      System.assertEquals(null,acct.Permanent_Hold_Out_Description__c);
      System.assertEquals(true,acct.Use_Zip_Assignment_Rules__c);
      
      acct.Use_Zip_Assignment_Rules__c = false;
      acct.HRS_Hold_Out_Expiration__c = Date.today().addDays(-5);
      acct.Premier_PBS_Hold_Out_Expiration__c = Date.today().addDays(-5);
      System.debug('testCheckAcctHoldOuts Test 4');
      System.assertEquals(true,ZipCheckOwner.checkAcctHoldOuts(acct,null,null,null));
      System.assertEquals(true,acct.Use_Zip_Assignment_Rules__c);
      System.assertEquals(false,acct.HRS_Hold_Out__c);
      System.assertEquals(null,acct.HRS_Hold_Out_Expiration__c);
      System.assertEquals(null,acct.HRS_Permanent_Hold_Out_Description__c);
      System.assertEquals(false,acct.Premier_PBS_Hold_Out__c);
      System.assertEquals(null,acct.Premier_PBS_Hold_Out_Expiration__c);
      System.assertEquals(null,acct.PEO_ASO_Permanent_Hold_Out_Description__c);
      
      acct.Use_Zip_Assignment_Rules__c = false;
      System.debug('testCheckAcctHoldOuts Test 5');
      System.assertEquals(false,ZipCheckOwner.checkAcctHoldOuts(acct,null,null,null));

   } // testCheckAcctHoldOuts
   
   static testMethod void testContactOwnership() {
      setupSegments();
      User u = [Select Id, Name, HR_Person_Id__c from User where isActive=true and DelegatedApproverId = null and id != :UserInfo.getUserId() and Profile.Name='System Administrator' limit 1];
      // get 3 test users
      User[] users = [Select Id, Name, HR_Person_Id__c from User where UserRoleId != null and ProfileId != null and isActive=true and DelegatedApproverId = null and id != :UserInfo.getUserId() and id != :u.Id and Sales_Org__c != null limit 6];
      User u1 = users[0];
      User u2 = users[1];
      User u3 = users[2];
      
      Account acct = new Account(Name='Account 1', OwnerId=u1.Id, HRS_Account_Owner__c=u2.Id, Premier_PBS_Account_Owner__c=u3.Id,Hold_Out__c=true, Hold_Out_Expiration__c=system.today().adddays(-5), Permanent_Hold_Out_Description__c='Payroll Sale');
      insert acct;
      
      Contact ctct = new Contact(AccountId=acct.Id, LastName='Test', Sales_Contact__c=true);
      insert ctct;
      
      ctct = [Select Id, OwnerId, HRS_Contact_Owner__c, Premier_PBS_Contact_Owner__c from Contact where Id=:ctct.Id];
      System.assertEquals(u1.Id, ctct.OwnerId);
      System.assertEquals(u2.Id, ctct.HRS_Contact_Owner__c);
      System.assertEquals(u3.Id, ctct.Premier_PBS_Contact_Owner__c);

   } // testContactOwnership

   static testMethod void testGetJoinCriteria() {
      setupSegments();
      Zip_Segment__c seg1 = coreSeg1;

      seg1.JoinCriteria__c += ZipCheckOwner.JOIN_AND+ZipCheckOwner.JOIN_BOOLEAN1;
      seg1.Boolean1Field__c = 'Hispanic_Ownership__c';

      User uCore1 = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE limit 1];
      
      Zip_Assignment__c[] v_zas = new Zip_Assignment__c[]{};
      Zip_Assignment__c za1 = ZipCheckOwnerTest.createZa('14514', uCore1, uCore1.Sales_Org__c, seg1.Name, seg1.Id, null, null, v_zas);
      
      ZipCheckOwner.getJoinCriteria(za1, seg1);
      System.assertEquals(true,ZipCheckOwner.hasEmps);
      System.assertEquals(false,ZipCheckOwner.hasAssets);
      System.assertEquals(true,ZipCheckOwner.hasBoolean1);
      System.assertEquals(false,ZipCheckOwner.hasBoolean2);
      System.assertEquals(true,ZipCheckOwner.isAnd);
      System.assertEquals(false,ZipCheckOwner.isOr);
      System.assertEquals(false,ZipCheckOwner.noJoin);
      /*
      za1.CriteriaToSkip__c = ZipCheckOwner.JOIN_BOOLEAN1;
      ZipCheckOwner.getJoinCriteria(za1, seg1);
      System.assertEquals(true,ZipCheckOwner.hasEmps);
      System.assertEquals(false,ZipCheckOwner.hasAssets);
      System.assertEquals(false,ZipCheckOwner.hasBoolean1);
      System.assertEquals(false,ZipCheckOwner.hasBoolean2);
      System.assertEquals(false,ZipCheckOwner.isAnd);
      System.assertEquals(false,ZipCheckOwner.isOr);
      System.assertEquals(true,ZipCheckOwner.noJoin);
      */
   } // testGetJoinCriteria
   
   static testMethod void testMiscMethods() {
        User uCore1 = [Select Id, Name, Sales_Org__c, HR_Person_Id__c, IsActive from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE limit 1];
        User uCore2 = [Select Id, Name, Sales_Org__c, HR_Person_Id__c, IsActive from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE 
                        and Id != :uCore1.Id limit 1];
       
        Referral_Account__c ra1 = new Referral_Account__c(OwnerId=uCore1.Id);           
        Referral_Account__c ra2 = new Referral_Account__c(OwnerId=uCore2.Id);
        Boolean checkAcctOwnerChange = ZipCheckOwner.checkForAcctOwnerChange(ra1, ra2);
        System.assertEquals(true, checkAcctOwnerChange);
        
        Account acct1 = new Account(OwnerId=uCore1.Id);
        List<Account> checkAccts = new List<Account>{acct1};
        List<String> personIds = new List<String>();
        personIds.add(String.valueOf(uCore1.HR_Person_Id__c));
        Map<String, User> getUserByPersonIdMap = ZipCheckOwner.getUserByPersonIdMap(personIds);
        System.assertEquals(1, getUserByPersonIdMap.size());
       
        //TODO: Add assertions
        
        
        
        Id userId;
        userId = ZipCheckOwner.checkUser(null, null, uCore1.Id);
        userId = ZipCheckOwner.checkUser(uCore2.Id, null, uCore1.Id);
        userId = ZipCheckOwner.checkUser(uCore1.Id, uCore2, uCore2.Id);
    
   } // testMiscMethods
    
   static testMethod void testSetOwnerWithHoldOut() {
      // we want to test setting an owner field that has a hold out, and make sure that the owner propagates to the account team and to the child account.
      setupZipsAndSegments(true);
       
      Schema.RecordTypeInfo rtCore = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT,ObjectHelper.OBJECT_ACCOUNT);
      Set<String> recordTypeIds = new Set<String>{rtCore.getRecordTypeId()};
          
      User[] users = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 4];
      
      Account parentAcct = new Account(Name='Parent Account', RecordTypeid=rtCore.getRecordTypeId(), NumberOfEmployees=30, ShippingPostalCode=zaHRS1Seg1.Name);
      insert parentAcct;
      parentAcct= getAccount(parentAcct.Id,recordTypeIds);
      System.assertNotEquals(null,parentAcct.HRS_Account_Owner__c);
      System.assertEquals(zaHRS1Seg1.User__c,parentAcct.HRS_Account_Owner__c);
      System.assertEquals(true, parentAcct.AccountTeamMembers.size() > 0);
      checkAtm(parentAcct, Label.AT_401K, zaHRS1Seg1.User__c);

      // setup children accounts
      ZipCheckOwner.accountIdsProcessedSet.clear();
      ZipCheckOwner.SKIP_TRIGGERS=false;
      TriggerMethods.clearVariables();
      Account child1 = new Account(Name='Child1', SalesParent__c=parentAcct.Id, NumberOfEmployees=2, RecordTypeid=rtCore.getRecordTypeId() );
      Account child2 = new Account(Name='Child2', SalesParent__c=parentAcct.Id, NumberOfEmployees=3, RecordTypeid=rtCore.getRecordTypeId() );
      Account child3 = new Account(Name='Child3', SalesParent__c=parentAcct.Id, NumberOfEmployees=4, RecordTypeid=rtCore.getRecordTypeId() );
      Account child4 = new Account(Name='Child4', SalesParent__c=parentAcct.Id, NumberOfEmployees=4, RecordTypeid=rtCore.getRecordTypeId()
                                   ,OwnerId=users[0].Id, Hold_Out__c=true,Permanent_Hold_Out_Description__c='Because' 
                                   ,HRS_Account_Owner__c=users[1].Id, HRS_Hold_Out__c=true, HRS_Permanent_Hold_Out_Description__c='Because');
      insert new Account[]{child1,child2,child3,child4};
          
      Account[] accts = ZipCheckOwner.getAccounts(new Id[]{parentAcct.Id, child1.Id, child2.Id, child3.Id, child4.Id},recordTypeIds);
      Map<Id,Account> acctMap = new Map<Id,Account>(accts);

      child1 = acctMap.get(child1.Id);
      System.assertEquals(zaHRS1Seg1.User__c,child1.HRS_Account_Owner__c);
      System.assertEquals(true, child1.AccountTeamMembers.size() > 0);
      checkAtm(child1, Label.AT_401K, zaHRS1Seg1.User__c);

      child2 = acctMap.get(child2.Id);
      System.assertEquals(zaHRS1Seg1.User__c,child2.HRS_Account_Owner__c);
      System.assertEquals(true, child2.AccountTeamMembers.size() > 0);
      checkAtm(child2, Label.AT_401K, zaHRS1Seg1.User__c);

      child3 = acctMap.get(child3.Id);
      System.assertEquals(zaHRS1Seg1.User__c,child3.HRS_Account_Owner__c);
      System.assertEquals(true, child3.AccountTeamMembers.size() > 0);
      checkAtm(child3, Label.AT_401K, zaHRS1Seg1.User__c);
       
      child4 = acctMap.get(child4.Id);
      System.assertEquals(users[0].Id,child4.OwnerId);
      System.assertEquals(users[1].Id,child4.HRS_Account_Owner__c);
      System.assertEquals(true, child4.AccountTeamMembers.size() > 0);
      //checkAtm(child4, Label.AT_401K, users[1].Id);
       
      // get another user to use - make sure not one already selected
      User newUser = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Id not in :usedUserIdSet limit 1];
      
      // make sure if we update the parent that it all propagates down to the children.
      ZipCheckOwner.accountIdsProcessedSet.clear();
      ZipCheckOwner.SKIP_TRIGGERS=false;
      TriggerMethods.clearVariables();
      parentAcct.HRS_Account_Owner__c = newUser.Id;
      parentAcct.HRS_Hold_Out__c = true;
      parentAcct.HRS_Permanent_Hold_Out_Description__c = 'Because';
      System.debug('before parent update newUser='+newUser.Id);
      Test.startTest();
      update parentAcct;
      Test.stopTest();
      
      accts = ZipCheckOwner.getAccounts(new Id[]{parentAcct.Id, child1.Id, child2.Id, child3.Id, child4.Id},recordTypeIds);
      acctMap = new Map<Id,Account>(accts);
      
      parentAcct = acctMap.get(parentAcct.Id);
      System.assertEquals(newUser.Id,parentAcct.HRS_Account_Owner__c);
      System.assertEquals(true, parentAcct.AccountTeamMembers.size() > 0);
      checkAtm(parentAcct, Label.AT_401K, newUser.Id);
       
      child1 = acctMap.get(child1.Id);
      System.assertEquals(newUser.Id,child1.HRS_Account_Owner__c);
      System.assertEquals(true, child1.AccountTeamMembers.size() > 0);
      checkAtm(child1, Label.AT_401K, newUser.Id);

      child2 = acctMap.get(child2.Id);
      System.assertEquals(newUser.Id,child2.HRS_Account_Owner__c);
      System.assertEquals(true, child2.AccountTeamMembers.size() > 0);
      checkAtm(child2, Label.AT_401K, newUser.Id);

      child3 = acctMap.get(child3.Id);
      System.assertEquals(newUser.Id,child3.HRS_Account_Owner__c);
      System.assertEquals(true, child3.AccountTeamMembers.size() > 0);
      checkAtm(child3, Label.AT_401K, newUser.Id);
       
      child4 = acctMap.get(child4.Id);
      System.assertEquals(users[0].Id,child4.OwnerId);
      System.assertEquals(users[1].Id,child4.HRS_Account_Owner__c);
      System.assertEquals(true, child4.AccountTeamMembers.size() > 0);
      //checkAtm(child4, Label.AT_401K, users[1].Id);

      ZipCheckOwner.accountIdsProcessedSet.clear();
      ZipCheckOwner.SKIP_TRIGGERS=false;
      TriggerMethods.clearVariables();
      // remove the holdouts from child4 - should inherit from parent
      child4.Hold_Out__c = false;
      child4.Permanent_Hold_Out_Description__c = null;
      child4.HRS_Hold_Out__c = false;
      child4.HRS_Permanent_Hold_Out_Description__c = null;
      update child4;
       
      accts = ZipCheckOwner.getAccounts(new Id[]{child4.Id},recordTypeIds);
      acctMap = new Map<Id,Account>(accts);
      
      child4 = acctMap.get(child4.Id);
      System.assertEquals(parentAcct.OwnerId,child4.OwnerId);
      System.assertEquals(parentAcct.HRS_Account_Owner__c,child4.HRS_Account_Owner__c);
      System.assertEquals(true, child4.AccountTeamMembers.size() > 0);
      checkAtm(child4, Label.AT_401K, parentAcct.HRS_Account_Owner__c);

   } // testSetOwnerWithHoldOut
    
   public static void checkAtm(Account acct, String roleName, Id userId) {
     AccountTeamMember foundAtm = null;
     System.debug('checkAtm acct='+acct.Name+' roleName='+roleName+' userId='+userId+' atms='+acct.AccountTeamMembers.size());
      for (AccountTeamMember atm : acct.AccountTeamMembers) {
         if (atm.TeamMemberRole == roleName) {
            foundAtm = atm;
            break;
         }
      } // for (AccountTeamMember atm
      System.assertNotEquals(null,foundAtm);
      System.assertEquals(userId,foundAtm.UserId);

   } // checkAtm
  
   static testMethod void testEvaluateCriteria() {
      ZipSegmentCriteria__c criteria1 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_BOOLEAN, FieldAPIName__c='CSSR_Segment__c', Values__c='True');
      ZipSegmentCriteria__c criteria2 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_BOOLEAN, FieldAPIName__c='CSSR_Segment__c', Values__c='False');
      Account testAcct = new Account(Name='Test Acct', CSSR_Segment__c=false);
      System.assertEquals(false,ZipCheckOwner.evaluateCriteria(testAcct,criteria1));
      System.assertEquals(true,ZipCheckOwner.evaluateCriteria(testAcct,criteria2));
      testAcct.CSSR_Segment__c=true;
      System.assertEquals(true,ZipCheckOwner.evaluateCriteria(testAcct,criteria1));
      System.assertEquals(false,ZipCheckOwner.evaluateCriteria(testAcct,criteria2));
       
      criteria1 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='Paychex_CAID__c', Values__c='CAID,CEID');
      criteria2 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='Paychex_CAID__c', Values__c=null);
      System.assertEquals(false,ZipCheckOwner.evaluateCriteria(testAcct,criteria1));
      System.assertEquals(true,ZipCheckOwner.evaluateCriteria(testAcct,criteria2));
      testAcct.Paychex_CAID__c='CAID';
      System.assertEquals(true,ZipCheckOwner.evaluateCriteria(testAcct,criteria1));
      System.assertEquals(false,ZipCheckOwner.evaluateCriteria(testAcct,criteria2));
      
      criteria1 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_NBR, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='NumberOfEmployees', Number1__c=5);
      criteria2 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_NBR, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='NumberOfEmployees', Number1__c=0);
      System.assertEquals(false,ZipCheckOwner.evaluateCriteria(testAcct,criteria1));
      System.assertEquals(true,ZipCheckOwner.evaluateCriteria(testAcct,criteria2));
      testAcct.NumberOfEmployees=5;
      System.assertEquals(true,ZipCheckOwner.evaluateCriteria(testAcct,criteria1));
      System.assertEquals(false,ZipCheckOwner.evaluateCriteria(testAcct,criteria2));
      criteria1.Operator__c=ZipCheckOwner.OP_NOT_EQUALS;
      criteria2.Operator__c=ZipCheckOwner.OP_NOT_EQUALS;
      System.assertEquals(false,ZipCheckOwner.evaluateCriteria(testAcct,criteria1));
      System.assertEquals(true,ZipCheckOwner.evaluateCriteria(testAcct,criteria2));
       
      criteria1.Operator__c=ZipCheckOwner.OP_GREATER;
      criteria2.Operator__c=ZipCheckOwner.OP_GREATER;
      System.assertEquals(false,ZipCheckOwner.evaluateCriteria(testAcct,criteria1));
      System.assertEquals(true,ZipCheckOwner.evaluateCriteria(testAcct,criteria2));
 
      criteria1.Operator__c=ZipCheckOwner.OP_GREATER_EQUALS;
      criteria2.Operator__c=ZipCheckOwner.OP_GREATER_EQUALS;
      System.assertEquals(true,ZipCheckOwner.evaluateCriteria(testAcct,criteria1));
      System.assertEquals(true,ZipCheckOwner.evaluateCriteria(testAcct,criteria2));

      criteria1.Operator__c=ZipCheckOwner.OP_LESS_EQUALS;
      criteria2.Operator__c=ZipCheckOwner.OP_LESS_EQUALS;
      System.assertEquals(true,ZipCheckOwner.evaluateCriteria(testAcct,criteria1));
      System.assertEquals(false,ZipCheckOwner.evaluateCriteria(testAcct,criteria2));

      criteria1.Operator__c=ZipCheckOwner.OP_LESS;
      criteria2.Operator__c=ZipCheckOwner.OP_LESS;
      System.assertEquals(false,ZipCheckOwner.evaluateCriteria(testAcct,criteria1));
      System.assertEquals(false,ZipCheckOwner.evaluateCriteria(testAcct,criteria2));

      criteria1 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_NBR_RANGE, FieldAPIName__c='NumberOfEmployees', Number1__c=5, Number2__c=7);
      criteria2 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_NBR_RANGE, FieldAPIName__c='NumberOfEmployees', Number1__c=0, Number2__c=4);
      System.assertEquals(true,ZipCheckOwner.evaluateCriteria(testAcct,criteria1));
      System.assertEquals(false,ZipCheckOwner.evaluateCriteria(testAcct,criteria2));

   } // testEvaluateCriteria
    
   static testMethod void testOwnerEvalWithCriteria() {
      String zip1='14624';
      String zip2='14625';
       
      User[] reps = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 7 ];
      User defRep = reps[0];
      
      User rep1 = reps[1];
      User rep2 = reps[2];
       
      System.debug('testOwnerEvalWithCriteria defRep='+defRep.Id+' rep1='+rep1.Id+' rep2='+rep2.Id);
      
      Schema.RecordTypeInfo acctRt = RecordTypeHelper.getRecordType('Core Account Record Type', ObjectHelper.OBJECT_ACCOUNT);
      Schema.RecordTypeInfo leadRt = RecordTypeHelper.getRecordType(Label.RT_Core_Lead, ObjectHelper.OBJECT_LEAD);
      Schema.RecordTypeInfo refAcctRt = RecordTypeHelper.getRecordType('Core Referral Source Record Type', ObjectHelper.OBJECT_REF_ACCOUNT);
      
      ZipCheckOwnerTest.segments = new Zip_Segment__c[]{};
      Zip_Segment__c seg_a = ZipCheckOwnerTest.createSegment(UserHelper.SO_CORE, null,null, '1','OwnerId', 'Hold_Out__c', 'Core Account Record Type',null
                              ,'OwnerId','Hold_Out__c','OwnerId','Hold_Out__c','OwnerId','Hold_Out__c');
      seg_a.LeadRecordTypeName__c = Label.RT_Core_Lead;
      seg_a.RfrlAcctDefault__c=true;
      seg_a.RfrlRecordTypes__c = 'Core Referral Source Record Type';
      
      Zip_Segment__c seg_b = ZipCheckOwnerTest.createSegment(UserHelper.SO_CORE, null,null, '2','OwnerId', 'Hold_Out__c', 'Core Account Record Type',null
                              ,'OwnerId','Hold_Out__c','OwnerId','Hold_Out__c','OwnerId','Hold_Out__c');
      seg_b.LeadRecordTypeName__c = Label.RT_Core_Lead;
      seg_b.RfrlAcctDefault__c=true;
      seg_b.RfrlRecordTypes__c = 'Core Referral Source Record Type';
       
      insert ZipCheckOwnerTest.segments;
           
      ZipSegmentCriteria__c criteria1a = new ZipSegmentCriteria__c(Account__c=true, Lead__c=true, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_NBR_RANGE, FieldAPIName__c='NumberOfEmployees', Number1__c=0, Number2__c=20);
      ZipSegmentCriteria__c criteria1b = new ZipSegmentCriteria__c(Account__c=true, Lead__c=true, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_NBR_RANGE, FieldAPIName__c='NumberOfEmployees', Number1__c=21, Number2__c=999);
      ZipSegmentCriteria__c criteria2a = new ZipSegmentCriteria__c(Account__c=true, Lead__c=false, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='Type', Values__c='Dan1,Dan2');
      ZipSegmentCriteria__c criteria2b = new ZipSegmentCriteria__c(Account__c=true, Lead__c=false, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='Type', Values__c='Dan3,Dan4');
      ZipSegmentCriteria__c criteria3a = new ZipSegmentCriteria__c(Account__c=false, Lead__c=false, ReferralAccount__c=true
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='City__c', Values__c='Rochester');
      ZipSegmentCriteria__c criteria3b = new ZipSegmentCriteria__c(Account__c=false, Lead__c=false, ReferralAccount__c=true
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='City__c', Values__c='Buffalo');
      ZipSegmentCriteria__c criteria4a = new ZipSegmentCriteria__c(Account__c=false, Lead__c=true, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='LeadSource', Values__c='Mailbox');
      ZipSegmentCriteria__c criteria4b = new ZipSegmentCriteria__c(Account__c=false, Lead__c=true, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='LeadSource', Values__c='Pony Express');
      insert new ZipSegmentCriteria__c[]{criteria1a,criteria1b,criteria2a,criteria2b,criteria3a,criteria3b,criteria4a,criteria4b};

      ZipSegmentCriteriaLink__c[] links = new ZipSegmentCriteriaLink__c[]{};
      links.add(new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_a.Id, ZipSegmentCriteria__c=criteria1a.Id));
      links.add(new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_a.Id, ZipSegmentCriteria__c=criteria2a.Id));
      links.add(new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_a.Id, ZipSegmentCriteria__c=criteria3a.Id));
      links.add(new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_a.Id, ZipSegmentCriteria__c=criteria4a.Id));
      links.add(new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_b.Id, ZipSegmentCriteria__c=criteria1b.Id));
      links.add(new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_b.Id, ZipSegmentCriteria__c=criteria2b.Id));
      links.add(new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_b.Id, ZipSegmentCriteria__c=criteria3b.Id));
      links.add(new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_b.Id, ZipSegmentCriteria__c=criteria4b.Id));
      insert links;
         
      Org_Unit__c dist = new Org_Unit__c(Name='10', Org_Unit_Name__c='District Dan', Org_Type__c='District', Sales_Org__c=UserHelper.SO_CORE);
      insert dist;
      
      ZipTerritory__c terr_a = new ZipTerritory__c(Name='Territory a', District__c=dist.Id, TerritoryRep__c=rep1.Id, Zip_Segment__c=seg_a.Id);
      ZipTerritory__c terr_b = new ZipTerritory__c(Name='Territory b', District__c=dist.Id, TerritoryRep__c=rep2.Id, Zip_Segment__c=seg_b.Id);
      insert new ZipTerritory__c[]{terr_a,terr_b};
      
      Zip_Assignment__c za_a = new Zip_Assignment__c(Name=zip1, District__c=dist.Id, Sales_Org__c=UserHelper.SO_CORE, ZipTerritory__c=terr_a.Id, User__c=rep1.Id, Zip_Segment__c=seg_a.Id);
      Zip_Assignment__c za_b = new Zip_Assignment__c(Name=zip1, District__c=dist.Id, Sales_Org__c=UserHelper.SO_CORE, ZipTerritory__c=terr_b.Id, User__c=rep2.Id, Zip_Segment__c=seg_b.Id);
      insert new Zip_Assignment__c[]{za_a, za_b};
         
      System.assertEquals(2, [select count() from Zip_Assignment_Change__c]);
       
      Lead ld1 = new Lead(OwnerId=defRep.Id, Company='Lead1',LastName='Last1', PostalCode=zip1, RecordTypeId=leadRt.getRecordTypeId(), NumberOfEmployees=10, LeadSource='Mailbox');
      Lead ld2 = new Lead(OwnerId=defRep.Id, Company='Lead2',LastName='Last2', PostalCode=zip1, RecordTypeId=leadRt.getRecordTypeId(), NumberOfEmployees=10, LeadSource='SomethingElse');
      Lead ld3 = new Lead(OwnerId=defRep.Id, Company='Lead3',LastName='Last3', PostalCode=zip1, RecordTypeId=leadRt.getRecordTypeId(), NumberOfEmployees=42, LeadSource='Pony Express');
      Lead ld4 = new Lead(OwnerId=defRep.Id, Company='Lead4',LastName='Last4', PostalCode=zip2, RecordTypeId=leadRt.getRecordTypeId(), NumberOfEmployees=42, LeadSource='Pony Express');
      LeadCheckOwner.processLeads(new Lead[]{ld1,ld2,ld3,ld4},false);
      //insert new Lead[]{ld1,ld2,ld3,ld4};

      //Map<Id,Lead> ldMap = new Map<Id,Lead>([Select Id, Name, OwnerId from Lead]);
      //System.assertEquals(rep1.Id, ldMap.get(ld1.Id).OwnerId);
      //System.assertEquals(defRep.Id, ldMap.get(ld2.Id).OwnerId);
      //System.assertEquals(rep2.Id, ldMap.get(ld3.Id).OwnerId);
      //System.assertEquals(defRep.Id, ldMap.get(ld4.Id).OwnerId);
    
      System.assertEquals(rep1.Id, ld1.OwnerId);
      //System.assertEquals(defRep.Id, ld2.OwnerId);
      //System.assertEquals(rep2.Id, ld3.OwnerId);
      //System.assertEquals(defRep.Id, ld4.OwnerId);

      Account acct1 = new Account(OwnerId=defRep.Id, Name='Account1', RecordTypeId=acctRt.getRecordTypeId(), NumberOfEmployees=9, Type='Dan1', ShippingPostalCode=zip1, Owner_Zip_Code__c=zip1);
      Account acct2 = new Account(OwnerId=defRep.Id, Name='Account2', RecordTypeId=acctRt.getRecordTypeId(), NumberOfEmployees=10, Type='Dan7', ShippingPostalCode=zip1, Owner_Zip_Code__c=zip1);
      Account acct3 = new Account(OwnerId=defRep.Id, Name='Account3', RecordTypeId=acctRt.getRecordTypeId(), NumberOfEmployees=42, Type='Dan3', ShippingPostalCode=zip1, Owner_Zip_Code__c=zip1);
      Account acct4 = new Account(OwnerId=defRep.Id, Name='Account3', RecordTypeId=acctRt.getRecordTypeId(), NumberOfEmployees=42, Type='Dan3', ShippingPostalCode=zip2, Owner_Zip_Code__c=zip2);
      insert new Account[]{acct1,acct2,acct3,acct4};
          
      Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Name, OwnerId from Account]);
      System.assertEquals(rep1.Id, acctMap.get(acct1.Id).OwnerId);
      System.assertEquals(defRep.Id, acctMap.get(acct2.Id).OwnerId);
      System.assertEquals(rep2.Id, acctMap.get(acct3.Id).OwnerId);
      System.assertEquals(defRep.Id, acctMap.get(acct4.Id).OwnerId);
       
      Referral_Account__c refAcct1 = new Referral_Account__c(OwnerId=defRep.Id, Name='RefAcct1', Zip_Postal_Code__c=zip1, City__c='Rochester', RecordTypeId=refAcctRt.getRecordTypeId());
      Referral_Account__c refAcct2 = new Referral_Account__c(OwnerId=defRep.Id, Name='RefAcct2', Zip_Postal_Code__c=zip1, City__c='Buffalo', RecordTypeId=refAcctRt.getRecordTypeId());
      Referral_Account__c refAcct3 = new Referral_Account__c(OwnerId=defRep.Id, Name='RefAcct3', Zip_Postal_Code__c=zip1, City__c='Syracuse', RecordTypeId=refAcctRt.getRecordTypeId());
      Referral_Account__c refAcct4 = new Referral_Account__c(OwnerId=defRep.Id, Name='RefAcct4', Zip_Postal_Code__c=zip2, City__c='Rochester', RecordTypeId=refAcctRt.getRecordTypeId());
      insert new Referral_Account__c[]{refAcct1,refAcct2,refAcct3,refAcct4};
          
      Map<Id,Referral_Account__c> refAcctMap = new Map<Id,Referral_Account__c>([Select Id, Name, OwnerId from Referral_Account__c]);
       ZipCheckOwner.getDefaultRecordTypes('Account');
       ZipCheckOwner.checkRefCtcts(new Referral_Account__c[]{refAcct1}, new List<Id>{refAcct1.Id});
       System.assertEquals(rep1.Id, refAcctMap.get(refAcct1.Id).OwnerId);
      //System.assertEquals(rep2.Id, refAcctMap.get(refAcct2.Id).OwnerId);
      System.assertEquals(defRep.Id, refAcctMap.get(refAcct3.Id).OwnerId);
      System.assertEquals(defRep.Id, refAcctMap.get(refAcct4.Id).OwnerId);
   } // testOwnerEvalWithCriteria
    
    public static testMethod void testLostClient() {
       setupZipsAndSegments(true);
       //setupCustomSettings();
       String zip1=zaCore1Seg1.Name;
       Schema.RecordTypeInfo rtCore = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT,ObjectHelper.OBJECT_ACCOUNT);
       Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, ObjectHelper.OBJECT_OPPTY);
       User u = [Select Id, Name, IsActive, Sales_Division__c, Sales_Org__c from User where isActive=true and Sales_Org__c =:UserHelper.SO_PAY and Sales_Division__c=:Label.VirtualSMBInbound_SalesDiv limit 1];
       Account acct = new Account(Name='TestLost 1',RecordTypeid=rtCore.getRecordTypeId(),ShippingPostalCode=zip1);
       insert acct;
       Opportunity opp1;
       System.runAs(u){
           opp1 = new Opportunity(RecordTypeId=rt.getRecordTypeId(),AccountId=acct.Id, Name='Opp1',StageName='Pending', CloseDate=Date.today());
           insert opp1;
       }
       acct.Lost_Date__c = Date.today();
       acct.LatestPayrollOpp__c = opp1.id;
       acct.Hold_Out__c = true;
       acct.Hold_Out_Expiration__c = Date.today().addDays(30);
       ZipCheckOwner.accountIdsProcessedSet.clear();
       TriggerMethods.clearVariables();
       update acct;
        
       System.assertEquals(opp1.OwnerId,acct.OwnerId);
   }
    
    static testMethod void testPEOClient() {
        setupZipsAndSegments(true);
        HoldOut_ExpirationDates__c hoPEO;
        hoPEO = new HoldOut_ExpirationDates__c(Name='PEO',Sales_Org__c='PEO',Account_Hold_Out__c='OasisPEOHoldOut__c',Account_Hold_Out_Date__c='OasisPEOHoldOutExpiration__c',
                                               InitialNumberofDays__c=365,Opportunity_Date__c='CloseDate',UseForOwnershipChange__c=true,HoldOutReasonFld__c='OasisPEOHoldOutReason__c'
                                               ,Account_Owner__c='OasisPEOAccountOwner__c',AccountTeamRole__c='PEO Centric Rep'
                                               ,StartDateSetsExpiration__c=365,StartDateHoldOutName__c='PEOReferMMSHoldOut');
        insert hoPEO;
        String zip1=zaCore1Seg1.Name;
        Schema.RecordTypeInfo rtCore = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT,ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo rtMMS = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_MMS, ObjectHelper.OBJECT_OPPTY);
        User u = [Select Id, Name, IsActive, Sales_Division__c, Sales_Org__c from User where isActive=true and Sales_Org__c='PEO' limit 1];
        Account acct = new Account(Name='TestPEO',RecordTypeid=rtCore.getRecordTypeId(),ShippingPostalCode=zip1);
        acct.First_Run_Date__c = System.today().addDays(-5);
        insert acct;
        Opportunity opp1;
        Opportunity opp;
        System.runAs(u){
            opp1 = new Opportunity(RecordTypeId=rtMMS.getRecordTypeId(),AccountId=acct.Id, Name='Opp1',StageName=label.OppStage_Won,CloseDate=Date.today(), Promotion__c = 'None',Primary_Oracle_Quote_Status__c = 'approved');
            insert opp1;  
            opp1.StageName='Sold - Commissioned';
            opp1.Pain_Points__c='HRIS';
            opp1.Products_of_Interest__c='Hiring & Onboarding';
            opp1.What_brought_them_to_Paychex__c='Bank';

            update opp1;
            opp = new Opportunity(RecordTypeId=rtMMS.getRecordTypeId(),AccountId=acct.Id,Name='Test Opp', StageName=label.OppStage_Won, CloseDate=Date.today().addDays(7), Promotion__c = 'None',Primary_Oracle_Quote_Status__c = 'approved');
            insert opp;
            opp.StageName='Sold - Commissioned'; 
            opp.Pain_Points__c='HRIS';
            opp.Products_of_Interest__c='Hiring & Onboarding';
            opp.What_brought_them_to_Paychex__c='Bank';
            update opp;
        }
        Referral_Partner__c refPartner = new Referral_Partner__c(Name='Test20',Partner_Type__c='Internal Referral',Sort_Order__c=20,Ref_To_Type__c='Referral Contact',CreateRefOpp__c=false, IsActive__c=true, Always_Check_Send_Email__c=false);
        insert refPartner;
        
        Referral__c ref = new Referral__c(Name='Test Ref', Referral_Id__c='TestId',NbrOfEmployees__c = 7,Account__c = acct.Id,Referral_Partner__c = refPartner.Id);
        ref.ActualRevenue__c = 777;
        ref.BranchClientNumber__c = '01-DAN1';
        ref.Disposition__c = 'SLD';
        ref.FedIdNumber__c = '12-4334567';
        ref.Referral_Approved_Date__c = System.today();
        ref.MonthSaleReported__c = Date.today().addDays(-7);
        ref.PendingRunOfPayroll__c = Date.today().addDays(-7);
        ref.Selling_Opportunity__c = opp1.Id;
        ref.Referring_Opportunity__c = opp.Id;
        insert ref;
        system.debug('Ref Referral :: ' + ref);
        
        acct.First_Run_Date__c = System.today().addDays(-4); 
        ZipCheckOwner.accountIdsProcessedSet.clear();
        TriggerMethods.clearVariables();
        update acct;
        System.assertEquals(opp.OwnerId,acct.OasisPEOAccountOwner__c);
    }

    static testMethod void testProspectRecordTypeChange() {
      String zip1='14624';
             
      User[] reps = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 7 ];
      User defRep = reps[0];      
      User rep1 = reps[1];
       
      System.debug('testProspectRecordTypeChange defRep='+defRep.Id+' rep1='+rep1.Id);
      
      Schema.RecordTypeInfo acctRt = RecordTypeHelper.getRecordType('Core Account Record Type', ObjectHelper.OBJECT_ACCOUNT);
      Schema.RecordTypeInfo acctRtMMS = RecordTypeHelper.getRecordType('MMS Account Record Type', ObjectHelper.OBJECT_ACCOUNT);
      
      ZipCheckOwnerTest.segments = new Zip_Segment__c[]{};
      Zip_Segment__c seg_a = ZipCheckOwnerTest.createSegment(UserHelper.SO_MMS, null,null, '1','OwnerId', 'Hold_Out__c', 'MMS Account Record Type',null
                              ,'OwnerId','Hold_Out__c','OwnerId','Hold_Out__c','OwnerId','Hold_Out__c');
      seg_a.LeadRecordTypeName__c = Label.RT_Core_Lead;       
      insert ZipCheckOwnerTest.segments;
           
      ZipSegmentCriteria__c criteria1a = new ZipSegmentCriteria__c(Account__c=true, Lead__c=true, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_NBR_RANGE, FieldAPIName__c='NumberOfEmployees', Number1__c=10, Number2__c=19);
      insert new ZipSegmentCriteria__c[]{criteria1a};

      ZipSegmentCriteriaLink__c[] links = new ZipSegmentCriteriaLink__c[]{};
      links.add(new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_a.Id, ZipSegmentCriteria__c=criteria1a.Id));
      insert links;
         
      Org_Unit__c dist = new Org_Unit__c(Name='10', Org_Unit_Name__c='District Dan', Org_Type__c='District', Sales_Org__c=UserHelper.SO_MMS);
      insert dist;
      
      ZipTerritory__c terr_a = new ZipTerritory__c(Name='Territory a', District__c=dist.Id, TerritoryRep__c=rep1.Id, Zip_Segment__c=seg_a.Id);
      insert new ZipTerritory__c[]{terr_a};
      
      Zip_Assignment__c za_a = new Zip_Assignment__c(Name=zip1, District__c=dist.Id, Sales_Org__c=UserHelper.SO_MMS, ZipTerritory__c=terr_a.Id, User__c=rep1.Id, Zip_Segment__c=seg_a.Id);
      insert new Zip_Assignment__c[]{za_a};
         
      System.assertEquals(1, [select count() from Zip_Assignment_Change__c]);
      
      Account acct1 = new Account(OwnerId=defRep.Id, Name='Account1', RecordTypeId=acctRt.getRecordTypeId(), NumberOfEmployees=15, Type='Dan1', ShippingPostalCode=zip1, Owner_Zip_Code__c=zip1);
      insert new Account[]{acct1};
          
      Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Name, OwnerId,RecordTypeId from Account]);
      System.assertEquals(acctRtMMS.getRecordTypeId(), acctMap.get(acct1.Id).RecordTypeId);
      System.assertEquals(rep1.Id, acctMap.get(acct1.Id).OwnerId);
   } // testProspectRecordTypeChange
    
    static testMethod void testClearSalesAccountTeams() {
      setupZipsAndSegments(true);
      
      // force the seg1 hrs team member to be set even though it doesn't meet the criteria
      // set the join criteria for the hrs segments
    Integer origNbrAcctTeams = 0;
      hrsSeg1.JoinCriteria__c = ZipCheckOwner.JOIN_EMPS;
      hrsSeg1.AlwaysAssignTeamMember__c=true;
      hrsSeg2.JoinCriteria__c = ZipCheckOwner.JOIN_EMPS;
      Zip_Segment__c[] segsToUpdate = new Zip_Segment__c[]{hrsSeg1,hrsSeg2};
      update segsToUpdate;
      
      Account acct1 = new Account(Name='Test Acct', NumberOfEmployees=150, ShippingPostalCode=zaCore1Seg1.Name);
      
      User sfdcData = [Select Id, Name, Email from User where Name=:UserHelper.SFDC_DATA and IsActive=true limit 1];
      System.runAs(sfdcData) {
         insert acct1;
      }

      AccountTeamMember[] atms = [Select Id, TeamMemberRole, UserId from AccountTeamMember where AccountId=:acct1.Id];
      system.debug('atms:'+atms);
      origNbrAcctTeams = atms.size();
    System.assertEquals(true,origNbrAcctTeams>0);
    
    // set Clear Sales Team
   acct1.Clear_Sales_Team__c=true;
   TriggerMethods.clearVariables();
   ZipCheckOwner.accountIdsProcessedSet.clear();
   update acct1;
   
   atms = [Select Id, AccountId, UserId, TeamMemberRole from AccountTeamMember where AccountId=:acct1.Id];
   system.debug('atms:'+atms);
   System.assertEquals(true,atms.size()!=origNbrAcctTeams);
        
   // reset Clear Sales Team
   acct1.Clear_Sales_Team__c=false;
   TriggerMethods.clearVariables();
   update acct1;
   
   // should be added back now
   atms = [Select Id, AccountId, UserId, TeamMemberRole from AccountTeamMember where AccountId=:acct1.Id];
   system.debug('atms:'+atms);
   System.assertEquals(true,atms.size()>0);      
   } // testClearSalesAccountTeams
    
    static testmethod void testClientTypeZipCriteria() {
        String zip1='14624';
                 
        User[] reps = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 7 ];
        User defRep = reps[0];      
        User rep1 = reps[1];
        
        Schema.RecordTypeInfo acctRt = RecordTypeHelper.getRecordType('Core Account Record Type', ObjectHelper.OBJECT_ACCOUNT);
    
        ZipCheckOwnerTest.segments = new Zip_Segment__c[]{};
        Zip_Segment__c seg_peo = ZipCheckOwnerTest.createSegment(UserHelper.SO_PEO, 0, 9999,'1','OasisPEOAccountOwner__c', 'OasisPEOHoldOut__c','Core Account Record Type',Label.AT_PEO_ASO,'OasisPEOOwner__c','Hold_Out__c',null,null,null,null);  
        seg_peo.Account_Segmentation_Type_Multi__c = 'Client';
        seg_peo.ClientType__c = 'Oasis Client';
        seg_peo.ClientTypeOperand__c = 'NOT EQUALS';
        insert ZipCheckOwnerTest.segments;
        
        Org_Unit__c dist = new Org_Unit__c(Name='10', Org_Unit_Name__c='District PEO', Org_Type__c='District', Sales_Org__c=UserHelper.SO_PEO);
        insert dist;
          
        ZipTerritory__c terr_a = new ZipTerritory__c(Name='Territory a', District__c=dist.Id, TerritoryRep__c=rep1.Id, Zip_Segment__c=seg_peo.Id);
        insert new ZipTerritory__c[]{terr_a};
          
        Zip_Assignment__c za_a = new Zip_Assignment__c(Name=zip1, District__c=dist.Id, Sales_Org__c=UserHelper.SO_PEO, ZipTerritory__c=terr_a.Id, User__c=rep1.Id, Zip_Segment__c=seg_peo.Id);
        insert new Zip_Assignment__c[]{za_a};
        
        Account acct1 = new Account(OwnerId=defRep.Id, Name='Account PEO', RecordTypeId=acctRt.getRecordTypeId(), NumberOfEmployees=15, Type='HR Solutions FLEX Client', ShippingPostalCode=zip1, Owner_Zip_Code__c=zip1,Bis_ID__c=1234,First_Run_Date__c=system.today());
        insert new Account[]{acct1};
        
        Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Name, OwnerId,RecordTypeId,OasisPEOAccountOwner__c from Account]);
        System.assertEquals(rep1.Id, acctMap.get(acct1.Id).OasisPEOAccountOwner__c);
     }
    
} // class ZipCheckOwnerTest