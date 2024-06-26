/**********************************************************
   Test methods for CadenceOwnerCheck.


   History
   --------
   01/24/2020 Dan Carmen        Created
   04/30/2020 Dan Carmen        Fix for tests failing
   11/17/2021 Dan Carmen        Fix save error record in list more than once
   02/10/2023 Dan Carmen        Do not update touchpoint if new owner is a queue

                              
/**********************************************************/
@isTest
private class CadenceOwnerCheckTest {

   @testSetup
   public static void setupData() {
      TriggerMethodsTest.createTriggerSetting('AccountAfter', false, true, false, false,new String[]{'CadenceOwnerCheck'});
      TriggerMethodsTest.createTriggerSetting('LeadAfter', false, true, false, false,new String[]{'CadenceOwnerCheck'});
      TriggerMethodsTest.createTriggerSetting('ReferralAccountAfter', false, true, false, false,new String[]{'CadenceOwnerCheck'});
      TriggerMethodsTest.saveSetupClasses();

      HoldOutExpirationMethodsTest.populateSetting();
      
      String[] cadenceNames = new String[]{'Cadence1','Cadence2a','Cadence2b','Cadence3a','Cadence3b'};
      String[] cadenceTypes = new String[]{'Payroll','Payroll','401k','Payroll','HNB'};
      Cadence__c[] cads = WorkQueueControllerTest.createCadences(cadenceNames,cadenceTypes);
      cads[0].OwnerChangeAction__c = CadenceOwnerCheck.ACTION_NOTHING;
      cads[1].OwnerChangeAction__c = CadenceOwnerCheck.ACTION_END;
      cads[2].OwnerChangeAction__c = CadenceOwnerCheck.ACTION_TXFER;
      cads[3].OwnerChangeAction__c = CadenceOwnerCheck.ACTION_TXFER;
      cads[4].OwnerChangeAction__c = CadenceOwnerCheck.ACTION_END;
      update cads;
   } // setupData
   
   public static Map<String,Cadence__c> getCadencesByName() {
      Cadence__c[] cads = [Select Id, Name, Cadence_Type__c, OwnerChangeAction__c from Cadence__c];
      Map<String,Cadence__c> cadMap = new Map<String,Cadence__c>();
      for (Cadence__c cad : cads) {
         cadMap.put(cad.Name, cad);
      }
      return cadMap;
   } // getCadencesByName

   static testMethod void testOwnerChangeAccount() {
      Map<String,Cadence__c> cadMap = getCadencesByName();
      
      User[] users = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 10];
      
      Account acct1 = new Account(Name='Acct1', OwnerId=users[0].Id);
      Account acct2 = new Account(Name='Acct2', OwnerId=users[1].Id, HRS_Account_Owner__c=users[2].Id);
      Account acct3 = new Account(Name='Acct3', OwnerId=users[3].Id, HNBF_Account_Owner__c=users[4].Id);
      ZipCheckOwner.SKIP_TRIGGERS=true;
      Account[] accts = new Account[]{acct1,acct2,acct3};
      insert accts;
      
      Contact ctct1 = new Contact(AccountId=acct1.Id, LastName='ContactLast1', Sales_Contact__c=true);
      Contact ctct2 = new Contact(AccountId=acct2.Id, LastName='ContactLast2', Sales_Contact__c=true);
      Contact ctct3 = new Contact(AccountId=acct3.Id, LastName='ContactLast3', Sales_Contact__c=true);
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = true;
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3};
      insert ctcts;
      
      acct1.SignificantContact__c = ctct1.Id;
      acct2.SignificantContact__c = ctct2.Id;
      acct3.SignificantContact__c = ctct3.Id;
      update accts;

      Cadence_Assignment_Record__c car1a = new Cadence_Assignment_Record__c(Name='Car1a',CadenceObject__c=acct1.Id, Cadence__c = cadMap.get('Cadence1').Id, Activity_Log__c='Car1a');
      car1a.Cadence_Owner__c = users[0].Id;
      Cadence_Assignment_Record__c car2a = new Cadence_Assignment_Record__c(Name='Car2a',CadenceObject__c=acct2.Id, Cadence__c = cadMap.get('Cadence2a').Id, Activity_Log__c='Car2a');
      car2a.Cadence_Owner__c = users[1].Id;
      Cadence_Assignment_Record__c car2b = new Cadence_Assignment_Record__c(Name='Car2b',CadenceObject__c=acct2.Id, Cadence__c = cadMap.get('Cadence2b').Id, Activity_Log__c='Car2b');
      car2b.Cadence_Owner__c = users[2].Id;
      Cadence_Assignment_Record__c car3a = new Cadence_Assignment_Record__c(Name='Car3a',CadenceObject__c=acct3.Id, Cadence__c = cadMap.get('Cadence3a').Id, Activity_Log__c='Car3aa');
      car3a.Cadence_Owner__c = users[3].Id;
      Cadence_Assignment_Record__c car3b = new Cadence_Assignment_Record__c(Name='Car3b',CadenceObject__c=acct3.Id, Cadence__c = cadMap.get('Cadence3b').Id, Activity_Log__c='Car3b');
      car3b.Cadence_Owner__c = users[4].Id;
      Cadence_Assignment_Record__c[] cars = new Cadence_Assignment_Record__c[]{car1a,car2a,car2b,car3a,car3b};
      insert cars;
      
      // should be five touchpoints created
      Map<Id,Cadence_Touchpoint__c> tpByCarMap = getTpByCarMap();
      System.assertEquals(5,tpByCarMap.size());
      
      // test initial state
      testTouchpointOwner(tpByCarMap.get(car1a.Id), users[0].Id);
      testTouchpointOwner(tpByCarMap.get(car2a.Id), users[1].Id);
      testTouchpointOwner(tpByCarMap.get(car2b.Id), users[2].Id);
      testTouchpointOwner(tpByCarMap.get(car3a.Id), users[3].Id);
      testTouchpointOwner(tpByCarMap.get(car3b.Id), users[4].Id);      
      
      Test.StartTest();
      acct1.OwnerId=users[5].Id;
      acct2.OwnerId=users[6].Id;
      acct2.HRS_Account_Owner__c=users[7].Id;
      acct3.OwnerId=users[8].Id;
      acct3.HNBF_Account_Owner__c=users[9].Id;
      ZipCheckOwner.SKIP_TRIGGERS=false;
      update accts;
      Test.StopTest();
      
      tpByCarMap = getTpByCarMap();
      // nothing should be touched
      testTouchpointOwner(tpByCarMap.get(car1a.Id), users[0].Id);
      testTouchpointStatus(tpByCarMap.get(car1a.Id), false);
      // should be ended, but owner remains
      testTouchpointOwner(tpByCarMap.get(car2a.Id), users[1].Id);
      testTouchpointStatus(tpByCarMap.get(car2a.Id), true);
      // records get a new owner
      testTouchpointOwner(tpByCarMap.get(car2b.Id), users[7].Id);
      testTouchpointStatus(tpByCarMap.get(car2b.Id), false);
      // records get a new owner
      testTouchpointOwner(tpByCarMap.get(car3a.Id), users[8].Id);
      testTouchpointStatus(tpByCarMap.get(car3a.Id), false);
      // should be ended, but owner remains
      testTouchpointOwner(tpByCarMap.get(car3b.Id), users[4].Id);      
      testTouchpointStatus(tpByCarMap.get(car3b.Id), true);

   } // testOwnerChangeAccount
   
   public static void testTouchpointOwner(Cadence_Touchpoint__c tp, Id ownerId) {
      System.assertEquals(ownerId, tp.OwnerId);
      System.assertEquals(ownerId, tp.CarRecord__r.OwnerId);
   } // testTouchpointOwner
   
   public static void testTouchpointStatus(Cadence_Touchpoint__c tp, Boolean isClosed) {
      System.debug('testTouchpointStatus Activity_Log__c='+tp.CarRecord__r.Activity_Log__c);
      if (isClosed) {
         System.assertEquals(Date.today(), tp.Close_Date__c);
         System.assertEquals('Closed', tp.Status__c);
         System.assertEquals(Date.today(), tp.CarRecord__r.Close_Date__c);
         System.assertEquals('Closed - Owner Changed', tp.CarRecord__r.CloseReason__c);
         System.assertEquals(true, tp.CarRecord__r.Closed__c);
         System.assertEquals('Closed', tp.CarRecord__r.Status__c);
      } else {
         System.assertEquals(null, tp.Close_Date__c);
         System.assertEquals('Open', tp.Status__c);
         System.assertEquals(null, tp.CarRecord__r.Close_Date__c);
         System.assertEquals(null, tp.CarRecord__r.CloseReason__c);
         System.assertEquals(false, tp.CarRecord__r.Closed__c);
         System.assertEquals('Open', tp.CarRecord__r.Status__c);
      }
   } // testTouchpointStatus
   
   public static Map<Id,Cadence_Touchpoint__c> getTpByCarMap() {
      Cadence_Touchpoint__c[] touchpoints = [Select Id, OwnerId
                                                   ,Close_Date__c
                                                   ,Status__c
                                                   ,CarRecord__c
                                                   ,CarRecord__r.Id
                                                   ,CarRecord__r.Name
                                                   ,CarRecord__r.AccountId__c
                                                   ,CarRecord__r.Activity_Log__c
                                                   ,CarRecord__r.Closed__c
                                                   ,CarRecord__r.OwnerId
                                                   ,CarRecord__r.Close_Date__c
                                                   ,CarRecord__r.CloseReason__c
                                                   ,CarRecord__r.Status__c
                                               From Cadence_Touchpoint__c];
      Map<Id,Cadence_Touchpoint__c> tpByCarMap = new Map<Id,Cadence_Touchpoint__c>();
      for (Cadence_Touchpoint__c tp : touchpoints) {
         tpByCarMap.put(tp.CarRecord__c, tp);
      }
      return tpByCarMap;
   } // getTpByCarMap

   static testMethod void testOwnerChangeLead() {
      Map<String,Cadence__c> cadMap = getCadencesByName();
      
      User[] users = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 10];
      
      Lead ld1 = new Lead(Company='Lead1', LastName='Lead1', OwnerId=users[0].Id);
      Lead ld2 = new Lead(Company='Lead2', LastName='Lead2', OwnerId=users[1].Id);
      Lead ld3 = new Lead(Company='Lead3', LastName='Lead3', OwnerId=users[2].Id);

      TriggerMethods.SKIP_TRIGGERS=true;
      Lead[] lds = new Lead[]{ld1,ld2,ld3};
      insert lds;
      
      Cadence_Assignment_Record__c car1a = new Cadence_Assignment_Record__c(Name='Car1a',CadenceObject__c=ld1.Id, Cadence__c = cadMap.get('Cadence1').Id);
      car1a.Cadence_Owner__c = users[0].Id;
      Cadence_Assignment_Record__c car2a = new Cadence_Assignment_Record__c(Name='Car2a',CadenceObject__c=ld2.Id, Cadence__c = cadMap.get('Cadence2a').Id);
      car2a.Cadence_Owner__c = users[1].Id;
      Cadence_Assignment_Record__c car3a = new Cadence_Assignment_Record__c(Name='Car3a',CadenceObject__c=ld3.Id, Cadence__c = cadMap.get('Cadence3a').Id);
      car3a.Cadence_Owner__c = users[2].Id;
      Cadence_Assignment_Record__c[] cars = new Cadence_Assignment_Record__c[]{car1a,car2a,car3a};
      insert cars;
      
      // should be three touchpoints created
      Map<Id,Cadence_Touchpoint__c> tpByCarMap = getTpByCarMap();
      System.assertEquals(3,tpByCarMap.size());
      
      // test initial state
      testTouchpointOwner(tpByCarMap.get(car1a.Id), users[0].Id);
      testTouchpointOwner(tpByCarMap.get(car2a.Id), users[1].Id);
      testTouchpointOwner(tpByCarMap.get(car3a.Id), users[2].Id);
      
      Test.StartTest();
      ld1.OwnerId=users[5].Id;
      ld2.OwnerId=users[6].Id;
      ld3.OwnerId=users[7].Id;
      TriggerMethods.SKIP_TRIGGERS=false;
      update lds;
      Test.StopTest();
      
      tpByCarMap = getTpByCarMap();
      // nothing should be touched
      testTouchpointOwner(tpByCarMap.get(car1a.Id), users[0].Id);
      testTouchpointStatus(tpByCarMap.get(car1a.Id), false);
      // should be ended, but owner remains
      testTouchpointOwner(tpByCarMap.get(car2a.Id), users[1].Id);
      testTouchpointStatus(tpByCarMap.get(car2a.Id), true);
      // records get a new owner
      testTouchpointOwner(tpByCarMap.get(car3a.Id), users[7].Id);
      testTouchpointStatus(tpByCarMap.get(car3a.Id), false);

   } // testOwnerChangeLead

   static testMethod void testOwnerChangeRefAcct() {
      Map<String,Cadence__c> cadMap = getCadencesByName();
      
      User[] users = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 10];
      
      Referral_Account__c refAcct1 = new Referral_Account__c(Name='Ref Acct1', OwnerId=users[0].Id);
      Referral_Account__c refAcct2 = new Referral_Account__c(Name='Ref Acct2', OwnerId=users[1].Id);
      Referral_Account__c refAcct3 = new Referral_Account__c(Name='Ref Acct3', OwnerId=users[2].Id);

      ReferralAccountMethods.SKIP_TRIGGERS=true;
      Referral_Account__c[] refAccts = new Referral_Account__c[]{refAcct1,refAcct2,refAcct3};
      insert refAccts;
      
      Cadence_Assignment_Record__c car1a = new Cadence_Assignment_Record__c(Name='Car1a',CadenceObject__c=refAcct1.Id, Cadence__c = cadMap.get('Cadence1').Id);
      car1a.Cadence_Owner__c = users[0].Id;
      Cadence_Assignment_Record__c car2a = new Cadence_Assignment_Record__c(Name='Car2a',CadenceObject__c=refAcct2.Id, Cadence__c = cadMap.get('Cadence2a').Id);
      car2a.Cadence_Owner__c = users[1].Id;
      Cadence_Assignment_Record__c car3a = new Cadence_Assignment_Record__c(Name='Car3a',CadenceObject__c=refAcct3.Id, Cadence__c = cadMap.get('Cadence3a').Id);
      car3a.Cadence_Owner__c = users[2].Id;
      Cadence_Assignment_Record__c[] cars = new Cadence_Assignment_Record__c[]{car1a,car2a,car3a};
      insert cars;
      
      // should be three touchpoints created
      Map<Id,Cadence_Touchpoint__c> tpByCarMap = getTpByCarMap();
      System.assertEquals(3,tpByCarMap.size());
      
      // test initial state
      testTouchpointOwner(tpByCarMap.get(car1a.Id), users[0].Id);
      testTouchpointOwner(tpByCarMap.get(car2a.Id), users[1].Id);
      testTouchpointOwner(tpByCarMap.get(car3a.Id), users[2].Id);
      
      Test.StartTest();
      refAcct1.OwnerId=users[5].Id;
      refAcct2.OwnerId=users[6].Id;
      refAcct3.OwnerId=users[7].Id;
      ReferralAccountMethods.SKIP_TRIGGERS=false;
      update refAccts;
      Test.StopTest();
      
      tpByCarMap = getTpByCarMap();
      // nothing should be touched
      testTouchpointOwner(tpByCarMap.get(car1a.Id), users[0].Id);
      testTouchpointStatus(tpByCarMap.get(car1a.Id), false);
      // should be ended, but owner remains
      testTouchpointOwner(tpByCarMap.get(car2a.Id), users[1].Id);
      testTouchpointStatus(tpByCarMap.get(car2a.Id), true);
      // records get a new owner
      testTouchpointOwner(tpByCarMap.get(car3a.Id), users[7].Id);
      testTouchpointStatus(tpByCarMap.get(car3a.Id), false);

   } // testOwnerChangeLead


} // class CadenceOwnerCheckTest