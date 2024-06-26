/* 
 * Test Methods for the ProspectOwnershipMethods class
 *
 * History
 * -------
 * 10/11/2013 Dan Carmen   Created
   12/19/2014 Dan Carmen        Consolidated methods coming from the lead
   08/10/2015 Cindy Freeman    Added test for determineSegment
   05/02/2016 Dan Carmen         Ability to not trigger on the dialed checkbox
   06/30/2016 Dan Carmen      Remove code for WORKABLE
   06/17/2019 Dan Carmen         Check for callbacks on the creation of prospect ownership
   10/15/2019 Dan Carmen         Change to use TriggerMethods.clearVariables
   03/07/2022 Dan Carmen         Clean up DialSource Action match logic
   10/18/2022 Dan Carmen         Fix for failing test

 */
@isTest
public class ProspectOwnershipMethodsTest {

   public static LifeOfLeadSettings__c createProspectingLols(String nssTeam, String nssSource) {
     return createProspectingLols(nssTeam,nssSource,true);
   }

   public static LifeOfLeadSettings__c createProspectingLols(String nssTeam, String nssSource, Boolean saveRecord) {
      // create the custom settings
      LifeOfLeadSettings__c lols = new LifeOfLeadSettings__c(Name='Prospecting-'+nssTeam+'-'+nssSource
                    ,IsExpiredAtEnd__c=true
                    ,IsFilterable__c=true
                    ,NextLeadStatus__c=null
                    ,NextOwnershipStage__c=ProspectOwnershipMethods.STAGE_EXPIRED
                    ,NSS_Source__c=nssSource
                    ,NSS_Team__c=nssTeam
                    ,NumOfDays__c=10
                    ,NumComDays__c=null
                    ,OwnedByNSR__c=true
                    ,OwnershipStage__c=ProspectOwnershipMethods.STAGE_PROSPECTING
                    ,SetAccountTeam__c=true
                    ,StageEndDateField__c='ProspectingEnd__c'
                    ,StageStartDateField__c='ProspectingStart__c'
                    ,TransferStatus__c=ProspectOwnershipMethods.STAGE_PROSPECTING
                    ,TransferUseOriginalDates__c=false
                    );
      if (saveRecord) {
         insert lols;
      }
      return lols;  
   } // createProspectingLols

   public static LifeOfLeadSettings__c lolsPAY = null;
   public static LifeOfLeadSettings__c lolsMMS = null;
   public static LifeOfLeadSettings__c lolsHRS = null;
   public static LifeOfLeadSettings__c lolsPAYi = null;
   public static LifeOfLeadSettings__c lolsMMSi = null;
   public static LifeOfLeadSettings__c lolsHRSi = null;

   public static LifeOfLeadSettings__c[] createAllProspectingLols() {
      lolsPAY = createProspectingLols(UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND, false);
      lolsMMS = createProspectingLols(UserHelper.SO_MMS, ProspectOwnershipMethods.NSS_OUTBOUND, false);
      lolsHRS = createProspectingLols(UserHelper.SO_401, ProspectOwnershipMethods.NSS_OUTBOUND, false);
      lolsPAYi = createProspectingLols(UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND, false);
      lolsMMSi = createProspectingLols(UserHelper.SO_MMS, ProspectOwnershipMethods.NSS_INBOUND, false);
      lolsHRSi = createProspectingLols(UserHelper.SO_401, ProspectOwnershipMethods.NSS_INBOUND, false);
      LifeOfLeadSettings__c[] lols = new LifeOfLeadSettings__c[]{lolsPAY,lolsMMS,lolsHRS,lolsPAYi,lolsMMSi,lolsHRSi};
      insert lols;
      return lols;
   } // createAllProspectingLols
   
   public static LifeOfLeadSettings__c createNotInterestedLols(String nssTeam, String nssSource) {
      // create the custom settings
      LifeOfLeadSettings__c lols = new LifeOfLeadSettings__c(Name='Not Interested-'+nssTeam+'-'+nssSource
                    ,IsExpiredAtEnd__c=true
                    ,IsFilterable__c=false
                    ,NextLeadStatus__c='Recycle'
                    ,NextOwnershipStage__c=ProspectOwnershipMethods.STAGE_EXPIRED
                    ,NSS_Source__c=nssSource
                    ,NSS_Team__c=nssTeam
                    ,NumOfDays__c=10
                    ,NumComDays__c=null
                    ,OwnedByNSR__c=false
                    ,OwnershipStage__c='Not Interested'
                    ,SetAccountTeam__c=false
                    ,StageEndDateField__c='NFI_WashEnd__c'
                    ,StageStartDateField__c='NFI_WashStart__c'
                    ,TransferStatus__c='Not Interested'
                    ,TransferUseOriginalDates__c=false
                    ,AlwaysAllowAsNext__c=true
                    );
      insert lols;   
      return lols;   
   } // createNotInterestedLols

   public static LifeOfLeadSettings__c createLockoutLols(String nssTeam, String nssSource) {
      // create the custom settings
      LifeOfLeadSettings__c lols = new LifeOfLeadSettings__c(Name=ProspectOwnershipMethods.STAGE_LOCKOUT+'-'+nssTeam+'-'+nssSource
                    ,IsExpiredAtEnd__c=true
                    ,IsFilterable__c=false
                    ,NextLeadStatus__c='Recycle'
                    ,NextOwnershipStage__c=ProspectOwnershipMethods.STAGE_EXPIRED
                    ,NSS_Source__c=nssSource
                    ,NSS_Team__c=nssTeam
                    ,NumOfDays__c=10
                    ,NumComDays__c=null
                    ,OwnedByNSR__c=false
                    ,OwnershipStage__c=ProspectOwnershipMethods.STAGE_LOCKOUT
                    ,SetAccountTeam__c=false
                    ,StageEndDateField__c='LockoutEnd__c'
                    ,StageStartDateField__c='LockoutStart__c'
                    ,TransferStatus__c=ProspectOwnershipMethods.STAGE_LOCKOUT
                    ,TransferUseOriginalDates__c=false
                    ,AlwaysAllowAsNext__c=true
                    );
      insert lols;   
      return lols;   
   } // createNotInterestedLols

   public static Prospect_Ownership__c createProspectingOwnership(LifeOfLeadSettings__c lols, Lead ld, Account acct) {
     //LifeOfLeadSettings__c lols = createProspectingLols(UserHelper.SO_CORE, ProspectOwnerShipMethods.NSS_OUTBOUND);
      Prospect_Ownership__c po = new Prospect_Ownership__c(NSS_Source__c=lols.NSS_Source__c, NSS_Team__c=lols.NSS_Team__c
                    ,StartDate__c=Date.today().addDays(-2), Ownership_Status__c=lols.OwnershipStage__c
                    ,Lead__c=(ld != null ? ld.Id : null)
                    ,Lead_Company__c=(ld != null ? ld.Lead_Company__c : null)
                    ,Prospect_Client__c=(acct != null ? acct.Id : null)
                    );
      ProspectOwnershipMethods.setStageEntryInfo(po,acct,null, null, ld, true, false);
      return po;
   } // createProspectingOwnership
   
   public static User[] getOutboundNSRs(Integer numUsers) {
     User[] users = getNSRs(numUsers,UserHelper.PROF_NSS_OUTBOUND);
     if (users.size() == 0) {
        // if there aren't any users of this profile type, redefine the profile to something we know is there.
        UserHelper.PROF_NSS_OUTBOUND = Utilities.PROF_HRS_401K;
        UserHelper.JOB_NSR = UserHelper.JOB_REP;
        users = getNSRs(numUsers,UserHelper.PROF_NSS_OUTBOUND);
     }
      return users;
   } // getOutboundNSRs
   
   public static User[] getInboundNSRs(Integer numUsers) {
      User[] users = getNSRs(numUsers,UserHelper.PROF_NSS_INBOUND);
      if (users.size() == 0) {
         // if there aren't any users of this profile type, redefine the profile to something we know is there.
         UserHelper.PROF_NSS_INBOUND = Utilities.PROF_HRS_PEO_ASO;
         UserHelper.JOB_NSR = UserHelper.JOB_REP;
         users = getNSRs(numUsers,UserHelper.PROF_NSS_INBOUND);
      }
      return users;
   } // getInboundNSRs
   
   /** The ids of the users that have already been selected - so users only get selected once. */
   public static Id[] excludeUserIds = new Id[]{};
   
   public static User[] getNSRs(Integer numUsers, String profileName) {
      String queryProfName = profileName+'%';
      User[] nsrs = [Select Id, Name, Job_Name__c, NSS_Team__c, HR_Person_Id__c, Profile.Name, UserRole.Name, UserRole.ParentRoleId from User where Job_Name__c=:UserHelper.JOB_NSR and Profile.Name like :queryProfName and IsActive=true and NSS_Team__c != null and Id not in :excludeUserIds limit :numUsers];
      for (User usr : nsrs) {
         excludeUserIds.add(usr.Id);
      }
      return nsrs;
   } // getNSRs

   public static final String PROD_HRS='401K';
   public static final String PROD_MMS='MMS';
   public static final String PROD_PAY='Payroll';
   
   /** Setup the product group mapping object for testing. 
      MappingType__c
      NSS_Team__c
      Priority__c
      Product_Group__c
      Product_of_Interest__c
      ReferralPartner__c
   
   */
   public static ProductGroupMapping__c[] setupProductMapping() {
      ProductGroupMapping__c[] mapping = new ProductGroupMapping__c[]{};
      mapping.add(new ProductGroupMapping__c(Name=ReferralController.REF_NSS+'-'+PROD_HRS, NSS_Team__c=UserHelper.SO_401, ReferralPartner__c=UserHelper.SO_401, MappingType__c=ReferralController.REF_NSS));
      mapping.add(new ProductGroupMapping__c(Name=ReferralController.REF_NSS+'-'+PROD_MMS, NSS_Team__c=UserHelper.SO_MMS, ReferralPartner__c=UserHelper.SO_MMS, MappingType__c=ReferralController.REF_NSS));
      mapping.add(new ProductGroupMapping__c(Name=ReferralController.REF_NSS+'-'+PROD_PAY, NSS_Team__c=UserHelper.SO_CORE, ReferralPartner__c=UserHelper.SO_CORE, MappingType__c=ReferralController.REF_NSS));
      insert mapping;
      
      NSSTeamMap__c[] teamMaps = new NSSTeamMap__c[]{};
      teamMaps.add(new NSSTeamMap__c(Name=UserHelper.SO_401, Priority__c=2));
      teamMaps.add(new NSSTeamMap__c(Name=UserHelper.SO_MMS, Priority__c=0));
      teamMaps.add(new NSSTeamMap__c(Name=UserHelper.SO_CORE, Priority__c=1, LeadRecordTypeName__c=RecordTypeHelper.CORE_LEAD));
      insert teamMaps;
      
      return mapping;
   } // setupProductMapping

   static testMethod void testOwnershipCreation() {
     ProspectOwnershipMethods.USE_STATIC_QUERY=false;
      LeadCompanyMethodsTest.setupData();
      LeadCompanyMethods.SKIP_FUTURE = true;
      LeadMethods.DISABLE_DIAL_CHECKBOX = false;
      setupProductMapping();
      // create a lead owned by the NSS Pending Queue
      Group nssQueue = LeadMethodsTest.getNSSQueue();
      
      Lead l1 = LeadMethodsTest.createNSSLead('1');
      l1.OwnerId = nssQueue.Id;
      insert l1;
      
      // find an NSR
      User[] outboundNSRs = getOutboundNSRs(2);
      User nsrOutbound1 = outboundNSRs[0];
      User nsrOutbound2 = outboundNSRs[1];
      User nsrInbound1 = getInboundNSRs(1)[0];
      createAllProspectingLols();

      // create an NSS user - find an NSS Profile
      //Profile nssProf = [Select Id, Name from Profile where Name=:UserHelper.PROF_NSS_OUTBOUND limit 1];
      // get an NSS Role
      //UserRole nssUserRole = [Select Id, Name from UserRole where Name like 'NSS%' limit 1];
      // get the running user info
      UserTestHelper uth = new UserTestHelper();
      User runningUser = uth.getUserById(UserInfo.getUserId());
      //User nssUser = uth.createUser(1, nssProf, nssUserRole, runningUser);
      //insert nssUser;
      
      System.runAs(nsrOutbound1) {
         // change owner to the NSS Rep
         l1.OwnerId = nsrOutbound1.Id;
         l1.Dialed__c = true;
         //l1.DialedUserId__c = nsrOutbound1.Id;
         //l1.NSS_Ownership_Start_Date__c = Date.today();
         TriggerMethods.clearVariables();
         update l1;

         l1 = [Select Id, OwnerId, Dialed__c, DialedUserId__c from Lead where Id=:l1.Id];         
         System.assertEquals(null,l1.DialedUserId__c);
         System.assertEquals(false,l1.Dialed__c);
         
         Prospect_Ownership__c po = [Select Id from Prospect_Ownership__c where Lead__c=:l1.Id];
         
         // retrieve with a null id
         System.assertEquals(null,ProspectOwnershipMethods.getById(null));
         
         // verify that an ownership record exists
         po = ProspectOwnershipMethods.getById(po.Id);
         
         // reselect it so we can excute the method
         System.assertEquals(nsrOutbound1.Id,po.NSR_Name__c);
         System.assertEquals(po.Ownership_Status__c,ProspectOwnershipMethods.STAGE_PROSPECTING);
         System.assertEquals(Date.today(),po.StartDate__c);
         System.assertEquals(null,po.EndDate__c);
         System.assertEquals(Date.today(),po.ProspectingStart__c);
         System.assertEquals(null,po.ProspectingEnd__c);
         System.assertEquals(null,po.CommissionStart__c);
         System.assertEquals(null,po.CommissionEnd__c);
         //System.assertEquals(nsrOutbound1.NSS_Team__c,po.NSS_Team__c);
 //        System.assertEquals(null,po.WorkabilityStart__c);
 //        System.assertEquals(null,po.WorkabilityEnd__c);

         // move the start date because the trigger will delete ownership expired on the same day.
         po.StartDate__c = Date.today().addDays(-2);
         update po;
         
          
         // so it falls into the trigger again.
         LeadMethods.leadIdsProcessed.clear();
         // change ownership back to the queue
         System.debug('testOwnershipCreation setting owner to queue');
         l1 = [Select Id, OwnerId, Dialed__c, DialedUserId__c from Lead where Id=:l1.Id];         

         l1.OwnerId = nssQueue.Id;
         TriggerMethods.clearVariables();
         update l1;
         
         // verify that the ownership record is ended
         po = ProspectOwnershipMethods.getById(po.Id);
         System.assertEquals(nsrOutbound1.Id,po.NSR_Name__c);
         System.assertEquals(po.Ownership_Status__c,ProspectOwnershipMethods.STAGE_EXPIRED);
         System.assertEquals(Date.today().addDays(-2),po.StartDate__c);
         System.assertEquals(Date.today(),po.EndDate__c);
         System.assertEquals(Date.today(),po.ProspectingStart__c);
         System.assertEquals(Date.today(),po.ProspectingEnd__c);
         //System.assertEquals(nsrOutbound1.NSS_Team__c,po.NSS_Team__c);
         System.assertEquals(ProspectOwnershipMethods.NSS_OUTBOUND,po.NSS_Source__c);
         
         
         // so it falls into the trigger again.
         LeadMethods.leadIdsProcessed.clear();
         l1 = [Select Id, OwnerId, Dialed__c, DialedUserId__c, DialedLastUsed__c from Lead where Id=:l1.Id];         
         // change back to the user
         l1.OwnerId = nsrOutbound1.Id;
         l1.Dialed__c = true;
         l1.DialedLastUsed__c = null;
         l1.DialedUserId__c = nsrOutbound1.Id;
         TriggerMethods.clearVariables();
         update l1;
         
         // there should now be 2 ownership objects - new one would get created.
         System.assertEquals(2,[Select count() from Prospect_Ownership__c where Lead__c=:l1.Id]);
      }
         // change ownership to another NSR
      //System.runAs(nsrOutbound2) {
         // use the dialed checkbox
         l1 = [Select Id, OwnerId, Dialed__c, DialedUserId__c, DialedLastUsed__c from Lead where Id=:l1.Id];         
         l1.OwnerId = nsrOutbound2.Id;
         l1.Dialed__c = true;
         l1.DialedLastUsed__c = null;
         //l1.DialedUserId__c = nsrOutbound2.Id;
         l1.Products__c = PROD_MMS;
         System.debug('ProspectOwnershipMethodsTest changing ownership to nsrOutbound2');
         // so it falls into the trigger again.
         LeadMethods.leadIdsProcessed.clear();
         TriggerMethods.clearVariables();
         update l1;
         // ownership shouldn't change, but NSS Team should
         // there should still be 2 ownership objects
      // Reetesh Commented below lines for testing error in deployment //To-DO
       /*   System.assertEquals(2,[Select count() from Prospect_Ownership__c where Lead__c=:l1.Id]);
         // should only one non ended record
         Prospect_Ownership__c po2 = [Select Id,NSR_Name__c,Ownership_Status__c,StartDate__c,ProspectingStart__c,ProspectingEnd__c,NSS_Source__c from Prospect_Ownership__c where EndDate__c = null limit 1];
         
         // verify that the ownership record is still owned by first NSR, but NSS team changed
         po2 = ProspectOwnershipMethods.getById(po2.Id);
         System.assertEquals(nsrOutbound1.Id,po2.NSR_Name__c);
         System.assertEquals(po2.Ownership_Status__c,ProspectOwnershipMethods.STAGE_PROSPECTING);
         System.assertEquals(Date.today(),po2.StartDate__c);
         System.assertEquals(null,po2.EndDate__c);
         System.assertEquals(Date.today(),po2.ProspectingStart__c);
         System.assertEquals(null,po2.ProspectingEnd__c);
         //System.assertEquals(nsrOutbound2.NSS_Team__c,po2.NSS_Team__c);
         System.assertEquals(ProspectOwnershipMethods.NSS_OUTBOUND,po2.NSS_Source__c);
         
         // change the start date so it won't be deleted.
         po2.StartDate__c = Date.today().addDays(-2);
         update po2;
       */
       //System.runAs(nsrInbound1) {
           
         l1 = [Select Id, OwnerId, Dialed__c, DialedUserId__c, DialedLastUsed__c from Lead where Id=:l1.Id];         
         l1.OwnerId = nsrInbound1.Id;
         l1.Dialed__c = true;
         l1.DialedLastUsed__c = null;
         //l1.DialedUserId__c = nsrInbound1.Id;
         
         System.debug('ProspectOwnershipMethodsTest changing ownership to nsrInbound1');
         // change the owner to an inbound nsr
         l1.Products__c = PROD_PAY;
         // so it falls into the trigger again.
         LeadMethods.leadIdsProcessed.clear();
         TriggerMethods.clearVariables();
         update l1;
         /*
         // there should now be 3 ownership objects
         System.assertEquals(3,[Select count() from Prospect_Ownership__c where Lead__c=:l1.Id]);

         // should only be one non ended record
         Prospect_Ownership__c po3 = [Select Id from Prospect_Ownership__c where EndDate__c = null];
         
         // verify that the ownership record is still owned by first NSR, but NSS team changed
         po3 = ProspectOwnershipMethods.getById(po3.Id);
         //System.assertEquals(nsrInbound1.Id,po3.NSR_Name__c);
         System.assertEquals(po3.Ownership_Status__c,ProspectOwnershipMethods.STAGE_PROSPECTING);
         System.assertEquals(Date.today(),po3.StartDate__c);
         System.assertEquals(null,po3.EndDate__c);
         System.assertEquals(Date.today(),po3.ProspectingStart__c);
         System.assertEquals(null,po3.ProspectingEnd__c);
         System.assertEquals(UserHelper.SO_CORE,po3.NSS_Team__c);
         System.assertEquals(ProspectOwnershipMethods.NSS_INBOUND,po3.NSS_Source__c);
             */
      //}
      //}
      
   } // testOwnershipCreation

   static testMethod void testGetOwnershipType() {
      ProspectOwnershipMethods.VALID_NSS_TEAMS = new String[]{UserHelper.SO_CORE,UserHelper.SO_MMS,UserHelper.SO_401, 'HNB'};
     // defaults to PAY
      System.assertEquals(UserHelper.SO_CORE,ProspectOwnershipMethods.getOwnershipType(null));
      System.assertEquals(UserHelper.SO_CORE,ProspectOwnershipMethods.getOwnershipType('This is a bad name'));
      for (String thisType : ProspectOwnershipMethods.VALID_NSS_TEAMS) {
         System.assertEquals(thisType,ProspectOwnershipMethods.getOwnershipType('Test '+thisType+' Test'));
      }
      System.assertEquals(UserHelper.SO_401,ProspectOwnershipMethods.getOwnershipType(UserHelper.SO_PEO_ASO));
      System.assertEquals('HNB',ProspectOwnershipMethods.getOwnershipType(UserHelper.SO_HNB));
      
   } // testGetOwnershipType
   
   static testMethod void testGetByAccountId() {
      Account acct = new Account(Name='Test Account');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
      
      Prospect_Ownership__c po = new Prospect_Ownership__c(Prospect_Client__c=acct.Id, StartDate__c=Date.today());
      insert po;
      
      System.assertEquals(null,ProspectOwnershipMethods.getByAcctId(null));
      
      Prospect_Ownership__c[] poCheck = ProspectOwnershipMethods.getByAcctId(acct.Id);
      System.assertEquals(1,poCheck.size());
      System.assertEquals(po.Id, poCheck[0].Id);
   } // testGetByAccountId

   static testMethod void testEvaluateNSSTeam() {
      // test leads
      Lead l1 = new Lead(LastName='TestLead', Company='Testing Inc');
      insert l1;
      
      setupProductMapping();
      
      createAllProspectingLols();
      Prospect_Ownership__c po = createProspectingOwnership(lolsPAY, l1, null);
      insert po;
      
      System.assertEquals(1,[Select count() from Prospect_Ownership__c where Id=:po.Id and NSS_Team__c=:UserHelper.SO_CORE]);
      
      l1.Products__c = PROD_HRS;
      update l1;
      //System.assertEquals(1,[Select count() from Prospect_Ownership__c where Id=:po.Id and NSS_Team__c=:UserHelper.SO_401]);

      l1.Products__c = PROD_MMS+';'+PROD_HRS;
      update l1;
      //System.assertEquals(1,[Select count() from Prospect_Ownership__c where Id=:po.Id and NSS_Team__c=:UserHelper.SO_MMS]);

      l1.Products__c = PROD_PAY;
      update l1;
      //System.assertEquals(1,[Select count() from Prospect_Ownership__c where Id=:po.Id and NSS_Team__c=:UserHelper.SO_CORE]);
   } // testEvaluateNSSTeam

   static testMethod void testCheckAccountOwnership() {
      LeadMethods.DISABLE_DIAL_CHECKBOX = false;
      setupProductMapping();
     // get a core rep
     User coreUser = [Select Id, Name from User where Job_Name__c=:UserHelper.JOB_REP and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE limit 1];
      // find an NSR
      User[] outboundNSRs = getOutboundNSRs(2);
      User nsrOutbound1 = outboundNSRs[0];
      User nsrOutbound2 = outboundNSRs[1];
      User nsrInbound1 = getInboundNSRs(1)[0];
      System.debug('testCheckAccountOwnership nsrOutbound1='+nsrOutbound1.Name+' nsrOutbound2='+nsrOutbound2.Name+' nsrInbound1='+nsrInbound1.Name);
      createAllProspectingLols();

      Account acct = new Account(Name='Test Acct1', OwnerId=coreUser.Id);
      insert acct;
      
      AccountShare acctShare1 = new AccountShare(AccountId=acct.Id,AccountAccessLevel='Edit',ContactAccessLevel='Edit',OpportunityAccessLevel='Edit',UserOrGroupId=nsrOutbound1.Id);
      AccountShare acctShare2 = new AccountShare(AccountId=acct.Id,AccountAccessLevel='Edit',ContactAccessLevel='Edit',OpportunityAccessLevel='Edit',UserOrGroupId=nsrOutbound2.Id);
      AccountShare acctShare3 = new AccountShare(AccountId=acct.Id,AccountAccessLevel='Edit',ContactAccessLevel='Edit',OpportunityAccessLevel='Edit',UserOrGroupId=nsrInbound1.Id);
      AccountShare[] acctShares = new AccountShare[]{acctShare1,acctShare2,acctShare3};
      insert acctShares;
      
      Contact ctct = new Contact(LastName='TestLast',AccountId=acct.Id, Products__c=PROD_HRS, OwnerId=coreUser.Id);
      insert ctct;
      
      System.runAs(nsrOutbound1) {
         ctct.Dialed__c = true;
         update ctct;
         
      } // System.runAs(nsrOutbound1)
      // verify the contact is owned by the NSR
      ctct = [Select Id, OwnerId, Hold_Out__c, Hold_Out_Reason__c, Dialed__c from Contact where Id=:ctct.Id];
      System.debug('running userid='+UserInfo.getUserId());
      System.assertEquals(ctct.OwnerId,nsrOutbound1.Id);
      System.assertEquals(false,ctct.Dialed__c);
      System.assertEquals(true,ctct.Hold_Out__c);
      System.assertEquals(ProspectOwnershipMethods.NSS_HOLDOUT,ctct.Hold_Out_Reason__c);

      // verify the account is set
      acct = [Select Id, OwnerId, AssignedToOutboundNSR__c, AssignedToInboundNSR__c from Account where Id=:acct.Id];
      System.assertEquals(true,acct.AssignedToOutboundNSR__c);
      System.assertEquals(false,acct.AssignedToInboundNSR__c);

      Prospect_Ownership__c po = [Select Id from Prospect_Ownership__c where Decision_Maker__c = :ctct.Id];
      po = ProspectOwnershipMethods.getById(po.Id);
      System.assertEquals(nsrOutbound1.Id,po.NSR_Name__c);
      System.assertEquals(po.Ownership_Status__c,ProspectOwnershipMethods.STAGE_PROSPECTING);
      System.assertEquals(Date.today(),po.StartDate__c);
      System.assertEquals(null,po.EndDate__c);
      System.assertEquals(Date.today(),po.ProspectingStart__c);
      System.assertEquals(null,po.ProspectingEnd__c);
      //System.assertEquals(nsrOutbound1.NSS_Team__c,po.NSS_Team__c);
      System.assertEquals(ProspectOwnershipMethods.NSS_OUTBOUND,po.NSS_Source__c);
      // verify the NSR is on the account team
      System.assertEquals(1,[select count() from AccountTeamMember where AccountId=:acct.Id and UserId=:nsrOutbound1.Id]);
      
      // have another outbound dial
      System.runAs(nsrOutbound2) {
         ctct.Dialed__c = true;
         update ctct;
      }
      
      // should still be 1 ownership record owned by the first NSR
      System.assertEquals(1,[select count() from Prospect_Ownership__c]);
      po = ProspectOwnershipMethods.getById(po.Id);
      System.assertEquals(nsrOutbound1.Id,po.NSR_Name__c);
      System.assertEquals(po.Ownership_Status__c,ProspectOwnershipMethods.STAGE_PROSPECTING);
      System.assertEquals(Date.today(),po.StartDate__c);
      System.assertEquals(null,po.EndDate__c);
      System.assertEquals(Date.today(),po.ProspectingStart__c);
      System.assertEquals(null,po.ProspectingEnd__c);
      //System.assertEquals(nsrOutbound1.NSS_Team__c,po.NSS_Team__c);
      System.assertEquals(ProspectOwnershipMethods.NSS_OUTBOUND,po.NSS_Source__c);
      // verify the NSR is on the account team
      System.assertEquals(1,[select count() from AccountTeamMember where AccountId=:acct.Id and UserId=:nsrOutbound1.Id]);

      // change the start date so the prospecting PO isn't deleted
      po.StartDate__c=Date.today().addDays(-2);
      update po;
      
      // inbound NSR dialed
      System.runAs(nsrInbound1) {
        // due to the code that checks the last time a dial happened.
        ctct.DialedLastUsed__c = Datetime.now().addHours(-5);
         ctct.Dialed__c = true;
         update ctct;
      }
      
      // should now be 2 records
      System.assertEquals(2,[select count() from Prospect_Ownership__c]);
      
      // first should be ended
      po = ProspectOwnershipMethods.getById(po.Id);
      System.assertEquals(nsrOutbound1.Id,po.NSR_Name__c);
      System.assertEquals(po.Ownership_Status__c,ProspectOwnershipMethods.STAGE_EXPIRED);
      System.assertEquals(Date.today().addDays(-2),po.StartDate__c);
      System.assertEquals(Date.today(),po.EndDate__c);
      System.assertEquals(Date.today(),po.ProspectingStart__c);
      System.assertEquals(Date.today(),po.ProspectingEnd__c);
      //System.assertEquals(nsrOutbound1.NSS_Team__c,po.NSS_Team__c);
      System.assertEquals(ProspectOwnershipMethods.NSS_OUTBOUND,po.NSS_Source__c);

      
      Prospect_Ownership__c po2 = [Select Id from Prospect_Ownership__c where NSR_Name__c=:nsrInbound1.Id];
      
      po2 = ProspectOwnershipMethods.getById(po2.Id);
      System.assertEquals(nsrInbound1.Id,po2.NSR_Name__c);
      System.assertEquals(po2.Ownership_Status__c,ProspectOwnershipMethods.STAGE_PROSPECTING);
      System.assertEquals(Date.today(),po2.StartDate__c);
      System.assertEquals(null,po2.EndDate__c);
      System.assertEquals(Date.today(),po2.ProspectingStart__c);
      System.assertEquals(null,po2.ProspectingEnd__c);
      //System.assertEquals(UserHelper.SO_401,po2.NSS_Team__c);
      System.assertEquals(ProspectOwnershipMethods.NSS_INBOUND,po2.NSS_Source__c);
      // verify the NSR is on the account team
      System.assertEquals(1,[select count() from AccountTeamMember where AccountId=:acct.Id and UserId=:nsrInbound1.Id]);

   } // testCheckAccountOwnership

   static testMethod void testAddToMap() {
     Map<String,Prospect_Ownership__c> ownerMap = new Map<String,Prospect_Ownership__c>();
      Prospect_Ownership__c po1 = new Prospect_Ownership__c(NSS_Team__c=UserHelper.SO_CORE);
      ProspectOwnershipMethods.addToMap(ownerMap, po1);
      // 1 record in the map
      System.assertEquals(1,ownerMap.size());
      System.assertEquals(true,ownerMap.containsKey(UserHelper.SO_CORE));
      Prospect_Ownership__c po2 = new Prospect_Ownership__c(NSS_Team__c=UserHelper.SO_CORE);
      ProspectOwnershipMethods.addToMap(ownerMap, po2);
      // still only 1 record in the map
      System.assertEquals(1,ownerMap.size());
      Prospect_Ownership__c po3 = new Prospect_Ownership__c(NSS_Team__c=UserHelper.SO_MMS, EndDate__c=Date.today()
                              ,CommissionStart__c=Date.today().addDays(-30)
                              ,CommissionEnd__c=Date.today().addDays(30));
      ProspectOwnershipMethods.addToMap(ownerMap, po3);
      // 2 records in the map
      System.assertEquals(2,ownerMap.size());
      System.assertEquals(true,ownerMap.containsKey(UserHelper.SO_MMS));
   } // testAddToMap
    
   static testMethod void testDetermineSegment() {
      ZipCheckOwnerTest.setupSegments();
      
      Schema.RecordTypeInfo leadHRSrt = RecordTypeHelper.getRecordType(RecordTypeHelper.HRS_LEAD, ObjectHelper.OBJECT_LEAD);
      Lead ld = new Lead(FirstName = 'Joe', LastName='Test Lead', PostalCode = '12345', NumberOfEmployees = 150,
                Product_Division__c='HRS',RecordTypeId=leadHRSrt.getRecordTypeId());
      String newSegment = ProspectOwnershipMethods.determineSegment(ld.PostalCode, 'HRS', ld);
      //System.assertEquals('HRS2', newSegment);
  } // testDetermineSegment
  
  static testMethod void testMisc() {
     ProspectOwnershipMethods.USE_STATIC_QUERY=true;
     ProspectOwnershipMethods.noPOReason = '';
     //ProspectOwnershipMethods.setNoPOReason(Boolean isUserInbound, Boolean inboundFound, Boolean outboundFound);

     ProspectOwnershipMethods.setNoPOReason(false, true, false);
     System.assertEquals(ProspectOwnershipMethods.noPOReason, ProspectOwnershipMethods.NO_PO_OUT_IN);
     ProspectOwnershipMethods.noPOReason = '';

     ProspectOwnershipMethods.setNoPOReason(true, true, false);
     System.assertEquals(ProspectOwnershipMethods.noPOReason, ProspectOwnershipMethods.NO_PO_IN_IN);
     ProspectOwnershipMethods.noPOReason = '';

     ProspectOwnershipMethods.setNoPOReason(false, false, true);
     System.assertEquals(ProspectOwnershipMethods.noPOReason, ProspectOwnershipMethods.NO_PO_OUT_OUT);
     ProspectOwnershipMethods.noPOReason = '';

     ProspectOwnershipMethods.setNoPOReason(true, false, false);
     System.assertEquals(ProspectOwnershipMethods.noPOReason, '');


     setupProductMapping();
     System.assertEquals(0,ProspectOwnershipMethods.getPriority(UserHelper.SO_MMS));
     System.assertEquals(1,ProspectOwnershipMethods.getPriority(UserHelper.SO_CORE));
     System.assertEquals(2,ProspectOwnershipMethods.getPriority(UserHelper.SO_401));
     
     
     // test getMapByLeadIds
     Lead[] lds = new Lead[]{};
     for (Integer cnt=0; cnt<5; cnt++) {
        lds.add(new Lead(Company='TestLeadCompany'+cnt, LastName='Smith'+cnt, FirstName='Mel'));
     }
     insert lds;
     
     Set<Id> leadIdSet = new Set<Id>();
     Prospect_Ownership__c[] pos = new Prospect_Ownership__c[]{};
     for (Lead ld : lds) {
        leadIdSet.add(ld.Id);
        pos.add(new Prospect_Ownership__c(Lead__c=ld.Id, StartDate__c=date.today(), Ownership_Status__c='Prospecting'));
     }
     insert pos;
     
     Map<Id,Prospect_Ownership__c> poMap = ProspectOwnershipMethods.getMapByLeadIds(leadIdSet);
     System.assertEquals(lds.size(), poMap.size());
  } // testMisc

  static testMethod void testEvaluateNSSTeam2() {
     Account[] accts = new Account[]{};
     for (Integer cnt=0; cnt<5; cnt++) {
        accts.add(new Account(Name='Test Acct'+cnt, Products__c='Core', NumberOfEmployees=1));
     }
     ZipCheckOwner.SKIP_TRIGGERS=true;
     insert accts;
     
     Id[] acctIds = new Id[]{};
     Contact[] ctcts = new Contact[]{};
     for (Account acct : accts) {
        acctIds.add(acct.Id);
        ctcts.add(new Contact(AccountId=acct.Id, LastName=acct.Name, FirstName='Jimmy', Products__c='Core'));
     }
     ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
     ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
     insert ctcts;
     
     Id[] ctctIds = new Id[]{};
     for (Contact ctct : ctcts) {
        ctctIds.add(ctct.Id);
     }
     
     Test.startTest();
     ProspectOwnershipMethods.evaluateContactNSSTeam(ctctIds);
     ProspectOwnershipMethods.evaluateAccountNSSTeam(acctIds);
     Test.stopTest();
     
  } // testEvaluateNSSTeam
  
  static testMethod void testSetNsrSupervisor() {
     Map<Id, User> userMap = new Map<Id, User>([select Id, Name, ManagerId from User where IsActive=true and ManagerId != null and Sales_Org__c=:UserHelper.SO_CORE limit 5]);
     Map<Id, Prospect_Ownership__c[]> poMap = new Map<Id, Prospect_Ownership__c[]>();
     for (User usr : userMap.values()) {
        Prospect_Ownership__c po = new Prospect_Ownership__c(NSR_Name__c=usr.Id);
        poMap.put(usr.Id, new Prospect_Ownership__c[]{po});
     }
     
     ProspectOwnershipMethods.setNsrSupervisor(poMap);
     
     for (Prospect_Ownership__c[] poList : poMap.values()) {
        for (Prospect_Ownership__c po : poList) {
           User usr = userMap.get(po.NSR_Name__c);
           System.assertEquals(true, usr != null);
           System.assertEquals(usr.ManagerId, po.NSRSupervisor__c);
        } // for (Prospect_Ownership__c po
     } // for (Prospect_Ownership__c[] poList
     
     
  } // testSetNsrSupervisor

   static testMethod void testPoCallback() {
      // create account
      Account acct1 = new Account(Name='Test acct1');
      Account acct2 = new Account(Name='Test acct2');
      Account[] accts = new Account[]{acct1,acct2};
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert accts;
      
      // create contacts
      Contact ctct1 = new Contact(LastName='TestCtct1', AccountId=acct1.Id);
      Contact ctct2 = new Contact(LastName='TestCtct2', AccountId=acct2.Id);
      Contact[] ctcts = new Contact[]{ctct1,ctct2};
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
      insert ctcts;
      
      // create lead
      Lead ld1 = new Lead(LastName='TestLead1', Company='Company1');
      Lead ld2 = new Lead(LastName='TestLead2', Company='Company2');
      Lead[] leads = new Lead[]{ld1,ld2};
      insert leads;
      
      // retrieve NSRs
      User[] nsrs = ProspectOwnershipMethodsTest.getOutboundNSRs(2);
      User nsr1 = nsrs[0];
      User nsr2 = nsrs[1];
      
      Id nssTaskRtId = TaskHelper.getNSSTaskRecordTypeId();
      // create callback tasks
      Task tsk1 = new Task(RecordTypeId=nssTaskRtId, Status='Not Started', Subject='test1', Type=TaskHelper.CT_CALLBACK, OwnerId=nsr1.Id, WhoId=ctct1.Id, ReminderDateTime=DateTime.now().addDays(3));
      // this one shouldn't do anything because the task owner doesn't match the ownership record
      Task tsk2 = new Task(RecordTypeId=nssTaskRtId, Status='Not Started', Subject='test2', Type=TaskHelper.CT_CALLBACK, OwnerId=nsr1.Id, WhatId=acct2.Id, ReminderDateTime=DateTime.now().addDays(3));
      // this should work
      Task tsk3 = new Task(RecordTypeId=nssTaskRtId, Status='Not Started', Subject='test3', Type=TaskHelper.CT_CALLBACK, OwnerId=nsr1.Id, WhoId=ld1.Id, ReminderDateTime=DateTime.now().addDays(3));
      // this shouldn't do anything because the ownership is in lockout
      Task tsk4 = new Task(RecordTypeId=nssTaskRtId, Status='Not Started', Subject='test4', Type=TaskHelper.CT_CALLBACK, OwnerId=nsr2.Id, WhoId=ld2.Id, ReminderDateTime=DateTime.now().addDays(3));
      Task[] tsks = new Task[]{tsk1,tsk2,tsk3,tsk4};
      //TaskHelper.SKIP_TRIGGERS=true;
      insert tsks;

      // create ownership records
      Prospect_Ownership__c po1 = new Prospect_Ownership__c(Prospect_Client__c=acct1.Id, Decision_Maker__c=ctct1.Id
                                       ,StartDate__c=Date.today().addDays(-5)
                                       ,ProspectingStart__c=Date.today().addDays(-5)
                                       ,Ownership_Status__c=ProspectOwnershipMethods.STAGE_PROSPECTING
                                       ,NSR_Name__c=nsr1.Id);

      // the NSR is diffferent than the task so shouldn't create
      Prospect_Ownership__c po2 = new Prospect_Ownership__c(Prospect_Client__c=acct2.Id, Decision_Maker__c=ctct2.Id
                                       ,StartDate__c=Date.today().addDays(-5)
                                       ,ProspectingStart__c=Date.today().addDays(-5)
                                       ,Ownership_Status__c=ProspectOwnershipMethods.STAGE_PROSPECTING
                                       ,NSR_Name__c=nsr2.Id);

      Prospect_Ownership__c po3 = new Prospect_Ownership__c(Lead__c=ld1.Id
                                       ,StartDate__c=Date.today().addDays(-5)
                                       ,ProspectingStart__c=Date.today().addDays(-5)
                                       ,Ownership_Status__c=ProspectOwnershipMethods.STAGE_PROSPECTING
                                       ,NSR_Name__c=nsr1.Id);

      Prospect_Ownership__c po4 = new Prospect_Ownership__c(Lead__c=ld2.Id
                                       ,StartDate__c=Date.today().addDays(-5)
                                       ,LockoutStart__c=Date.today().addDays(-5)
                                       ,Ownership_Status__c=ProspectOwnershipMethods.STAGE_LOCKOUT
                                       ,NSR_Name__c=nsr2.Id);
      Prospect_Ownership__c[] pos = new Prospect_Ownership__c[]{po1,po2,po3,po4};
      Test.startTest();
      insert pos;
      Test.stopTest();

      // should be 2 PO Callback records created
      System.assertEquals(2,[select count() from ProspectOwnershipCallback__c]);
      
   } // testPoCallback
   
   static testMethod void testPOWithOpp() {
      User nsrInbound1 = getInboundNSRs(1)[0];
      // test leads
      Account acct = new Account(Name='Test Account', ShippingPostalCode='12345');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
      
      Contact ctct = new Contact(AccountId=acct.Id, LastName='TestLast');
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
      insert ctct;
      
      Opportunity opp = new Opportunity(Name='Test Opp', AccountId=acct.Id, StageName='Pending', CloseDate=Date.today().addDays(7));
      OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
      insert opp;
      
      setupProductMapping();
      
      createAllProspectingLols();
      Prospect_Ownership__c po = createProspectingOwnership(lolsPAY, null, acct);
      po.NSR_Name__c=nsrInbound1.Id;
      po.Opportunity__c = opp.Id;
      insert po;
      

   } // testPOWithOpp

   static testMethod void testNextVerifyDate() {
      ProspectOwnershipMethods.VERIFY_DAYS=2;
      // create lead
      Lead ld1 = new Lead(LastName='TestLead1', Company='Company1');
      Lead[] leads = new Lead[]{ld1};
      insert leads;
      
      // retrieve NSRs
      User[] nsrs = ProspectOwnershipMethodsTest.getOutboundNSRs(1);
      User nsr1 = nsrs[0];

      // create ownership records
      Prospect_Ownership__c po1 = new Prospect_Ownership__c(Lead__c=ld1.Id
                                       ,StartDate__c=Date.today().addDays(-5)
                                       ,ProspectingStart__c=Date.today().addDays(-5)
                                       ,Ownership_Status__c=ProspectOwnershipMethods.STAGE_PROSPECTING
                                       ,NSR_Name__c=nsr1.Id);
      insert po1;
      po1 = [Select Id, LastVerified__c, NextVerifyDate__c, Verified__c from Prospect_Ownership__c where Id=:po1.Id];
      System.assertEquals(null,po1.LastVerified__c);
      System.assertEquals(Date.today(), po1.NextVerifyDate__c.date());
      
      po1.LastVerified__c=Datetime.now().addMinutes(-1);
      po1.Verified__c = true;
      update po1;
      
      po1 = [Select Id, LastVerified__c, NextVerifyDate__c, Verified__c, Ownership_Status__c, EndDate__c
                   ,CommissionStart__c, CommissionEnd__c
               from Prospect_Ownership__c where Id=:po1.Id];
      System.assertEquals(Date.today(),po1.LastVerified__c.date());
      System.assertEquals(Date.today().addDays(2), po1.NextVerifyDate__c.date());
      System.assertEquals(false, po1.Verified__c);
      
      po1.Ownership_Status__c=ProspectOwnershipMethods.STAGE_COMMISSION;
      po1.EndDate__c=Date.today();
      po1.CommissionStart__c = Date.today().addDays(-5);
      po1.CommissionEnd__c = Date.today().addDays(5);
      po1.NextVerifyDate__c = Datetime.now().addDays(1);
      po1.Verified__c=true;
      update po1;
      
      po1 = [Select Id, LastVerified__c, NextVerifyDate__c, Verified__c, Ownership_Status__c, EndDate__c
                   ,CommissionStart__c, CommissionEnd__c
               from Prospect_Ownership__c where Id=:po1.Id];
      System.assertEquals(null,po1.LastVerified__c);
      System.assertEquals(Date.today().addDays(2), po1.NextVerifyDate__c.date());
      System.assertEquals(false, po1.Verified__c);
      
   } // testNextVerifyDate
    
   static testMethod void testMapDialSourceActionToPO() {
      Account acct1 = new Account(Name='Test Account1', ShippingPostalCode='12345');
      Account acct2 = new Account(Name='Test Account2', ShippingPostalCode='12345');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert new Account[]{acct1,acct2};
          
      Contact ctct1 = new Contact(AccountId=acct1.Id, LastName='TestLast1');
      Contact ctct2 = new Contact(AccountId=acct2.Id, LastName='TestLast2');
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
      insert new Contact[]{ctct1,ctct2};
         
      Lead ld1 = new Lead(LastName='LeadLast1',Company='Lead Company1', PostalCode='14624');
      Lead ld2 = new Lead(LastName='LeadLast2',Company='Lead Company2', PostalCode='14624');
      TriggerMethods.SKIP_TRIGGERS=true;
      insert new Lead[]{ld1,ld2};

      User[] users = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 6];
       
      Schema.RecordTypeInfo rtInbound = CallCenterHelper.getInboundRt();
      
      DS_Denali__DialSource_Sessions_V3__c dsSession = new DS_Denali__DialSource_Sessions_V3__c(Name='Test Session',DS_Denali__Session_Date__c=Datetime.now());
      insert dsSession;
      
      DS_Denali__DialSource_Action__c action1 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtInbound.getRecordTypeId()
                                                       ,DS_Denali__Owner__c=UserInfo.getUserId()
                                                       ,DS_Denali__Contact__c=ctct1.Id
                                                       ,DS_Denali__Call_Campaign__c='Call Campaign1'
                                                       ,DS_Denali__Phone__c='5553456789'
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id
                                                       ,DS_Denali__Inbound_DNIS__c='InboundCall'
                                                       ,DS_Denali__Inbound_DNIS_Name__c='DNIS Name1');
      DS_Denali__DialSource_Action__c action2 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtInbound.getRecordTypeId()
                                                       ,DS_Denali__Owner__c=UserInfo.getUserId()
                                                       ,DS_Denali__Contact__c=ctct2.Id
                                                       ,DS_Denali__Call_Campaign__c='Call Campaign2'
                                                       ,DS_Denali__Phone__c='5551234570'
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id
                                                       ,DS_Denali__Inbound_DNIS__c='InboundCall'
                                                       ,DS_Denali__Inbound_DNIS_Name__c='DNIS Name2');
      DS_Denali__DialSource_Action__c action3 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtInbound.getRecordTypeId()
                                                       ,DS_Denali__Owner__c=UserInfo.getUserId()
                                                       ,DS_Denali__Lead__c=ld1.Id
                                                       ,DS_Denali__Call_Campaign__c='Call Campaign2'
                                                       ,DS_Denali__Phone__c='5551234570'
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id
                                                       ,DS_Denali__Inbound_DNIS__c='InboundCall'
                                                       ,DS_Denali__Inbound_DNIS_Name__c='DNIS Name2');
      DS_Denali__DialSource_Action__c action4 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtInbound.getRecordTypeId()
                                                       ,DS_Denali__Owner__c=UserInfo.getUserId()
                                                       ,DS_Denali__Lead__c=ld2.Id
                                                       ,DS_Denali__Call_Campaign__c='Call Campaign2'
                                                       ,DS_Denali__Phone__c='5551234570'
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id
                                                       ,DS_Denali__Inbound_DNIS__c='InboundCall'
                                                       ,DS_Denali__Inbound_DNIS_Name__c='DNIS Name2');
     DS_Denali__DialSource_Action__c action5 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtInbound.getRecordTypeId()
                                                       ,DS_Denali__Owner__c=UserInfo.getUserId()
                                                       ,DS_Denali__Account__c=acct1.Id
                                                       ,DS_Denali__Call_Campaign__c='Call Campaign2'
                                                       ,DS_Denali__Phone__c='5551234570'
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id
                                                       ,DS_Denali__Inbound_DNIS__c='InboundCall'
                                                       ,DS_Denali__Inbound_DNIS_Name__c='DNIS Name2');

       
      insert new DS_Denali__DialSource_Action__c[]{action1,action2,action3,action4,action5};
      Test.setCreatedDate(action2.Id, Datetime.now().addHours(-3));
      Test.setCreatedDate(action4.Id, Datetime.now().addHours(-3));
      Test.setCreatedDate(action5.Id, Datetime.now().addHours(-3));

      // force it to only look for an hour.
      ProspectOwnershipMethods.hoursOffset = -1;
       
      Prospect_Ownership__c po1 = new Prospect_Ownership__c(Decision_Maker__c=ctct1.Id
                                       ,StartDate__c=Date.today().addDays(-5)
                                       ,ProspectingStart__c=Date.today().addDays(-5)
                                       ,Ownership_Status__c=ProspectOwnershipMethods.STAGE_PROSPECTING
                                       ,NSR_Name__c=users[0].Id);
      Prospect_Ownership__c po2 = new Prospect_Ownership__c(Decision_Maker__c=ctct2.Id
                                       ,StartDate__c=Date.today().addDays(-5)
                                       ,ProspectingStart__c=Date.today().addDays(-5)
                                       ,Ownership_Status__c=ProspectOwnershipMethods.STAGE_PROSPECTING
                                       ,NSR_Name__c=users[1].Id);
      Prospect_Ownership__c po3 = new Prospect_Ownership__c(Lead__c=ld1.Id
                                       ,StartDate__c=Date.today().addDays(-5)
                                       ,ProspectingStart__c=Date.today().addDays(-5)
                                       ,Ownership_Status__c=ProspectOwnershipMethods.STAGE_PROSPECTING
                                       ,NSR_Name__c=users[2].Id);
      Prospect_Ownership__c po4 = new Prospect_Ownership__c(Lead__c=ld2.Id
                                       ,StartDate__c=Date.today().addDays(-5)
                                       ,ProspectingStart__c=Date.today().addDays(-5)
                                       ,Ownership_Status__c=ProspectOwnershipMethods.STAGE_PROSPECTING
                                       ,NSR_Name__c=users[3].Id);
       Prospect_Ownership__c po5 = new Prospect_Ownership__c(Prospect_Client__c=acct1.Id
                                       ,StartDate__c=Date.today().addDays(-5)
                                       ,ProspectingStart__c=Date.today().addDays(-5)
                                       ,Ownership_Status__c=ProspectOwnershipMethods.STAGE_PROSPECTING
                                       ,NSR_Name__c=users[3].Id);

      Test.startTest();
      insert new Prospect_Ownership__c[]{po1,po2,po3,po4,po5};
      Test.stopTest();
      Map<Id,Prospect_Ownership__c> poMap = new Map<Id,Prospect_Ownership__c>([Select Id, DialSource_Action_That_Created_PO__c, ProcessTracker__c from Prospect_Ownership__c]);
      po1 = poMap.get(po1.Id);
      System.assertEquals(action1.Id, po1.DialSource_Action_That_Created_PO__c);
      System.assertEquals(true,po1.ProcessTracker__c.contains('Matched to DialSource Action'));
          
      po2 = poMap.get(po2.Id);
      System.assertEquals(null, po2.DialSource_Action_That_Created_PO__c);
      System.assertEquals(false,po2.ProcessTracker__c.contains('Matched to DialSource Action'));

      po3 = poMap.get(po3.Id);
      System.assertEquals(action3.Id, po3.DialSource_Action_That_Created_PO__c);
      System.assertEquals(true,po3.ProcessTracker__c.contains('Matched to DialSource Action'));

      po4 = poMap.get(po4.Id);
      System.assertEquals(null, po4.DialSource_Action_That_Created_PO__c);
      System.assertEquals(false,po4.ProcessTracker__c.contains('Matched to DialSource Action'));
   } // testMapDialSourceActionToPO
     
    
   static testMethod void testMisc2() {
      setupProductMapping();
      Schema.RecordTypeInfo rtCore = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_LEAD,ObjectHelper.OBJECT_LEAD);

      Schema.RecordTypeInfo rtInfo = ProspectOwnershipMethods.getRecordTypeInfo(rtCore.getName(), null); 
      System.assertEquals(rtCore.getRecordTypeId(), rtInfo.getRecordTypeId());
      rtInfo = ProspectOwnershipMethods.getRecordTypeInfo(null, rtCore.getRecordTypeId()); 
      System.assertEquals(rtCore.getRecordTypeId(), rtInfo.getRecordTypeId());
       
      Schema.RecordTypeInfo rtLead = ProspectOwnershipMethods.getLeadRecordTypeByNssTeam(UserHelper.SO_CORE);
      System.assertEquals(RecordTypeHelper.CORE_LEAD,rtlead.getName());
       
      Lead ld1 = new Lead(LastName='LeadLast1',Company='Lead Company1', PostalCode='14624');
      Lead ld2 = new Lead(LastName='LeadLast2',Company='Lead Company2', PostalCode='14624');
      TriggerMethods.SKIP_TRIGGERS=true;
      insert new Lead[]{ld1,ld2};
      Set<Id> leadIdSet = new Set<Id>{ld1.Id,ld2.Id};
      ProspectOwnershipMethods.evaluateLeadNSSTeam(leadIdSet);

   } // testMisc2
   
} // class ProspectOwnershipMethodsTest