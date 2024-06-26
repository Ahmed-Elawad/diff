/** Queueable process to update Accounts/Leads based on CAR updates
 * 
 * History
 * -------
   11/05/2019   Dan Carmen      Created
   03/30/2019   Dan Carmen              Add Last Cadence Name
   05/08/2020   Dan Carmen              Fix the calculation of latest cadence info.
   05/24/2021   Dan Carmen              Add Referral Account
   08/29/2022   Dan Carmen              Add additional debug when running as a queueable
   10/10/2022   Dan Carmen              Fix to set flag correctly with bulk load
   02/03/2023   Dan Carmen              Check for nulls

*/
@isTest
public class CadenceQueueableTest {

   @testSetup
   Static void setupData() {
      TriggerMethodsTest.createTriggerSetting('AccountBefore', true, false, false, false, new String[]{'CadenceHelper'});
      TriggerMethodsTest.createTriggerSetting('LeadBefore', true, false, false, false, new String[]{'CadenceHelper'});
      TriggerMethodsTest.createTriggerSetting('ReferralAccountBefore', true, false, false, false, new String[]{'CadenceHelper'});
      TriggerMethodsTest.saveSetupClasses();

      CadenceUpdateTest.setupTestCadence();
   } // setupData
    
   static testMethod void testCarUpdates() {
      User runningUser = UserHelper.getRunningUser();
      Account acct1 = new Account(Name='Acct1', OwnerId=runningUser.Id);
      Account acct2 = new Account(Name='Acct2', OwnerId=runningUser.Id);
      Account acct3 = new Account(Name='Acct3', OwnerId=runningUser.Id);
      ZipCheckOwner.SKIP_TRIGGERS=true; 
      Account[] accts = new Account[]{acct1,acct2,acct3};
      insert accts;
       
      Lead ld5 = new Lead(LastName='Lead5', Company='Lead5', OwnerId=runningUser.Id);
      Lead ld6 = new Lead(LastName='Lead6', Company='Lead6',In_Cadence__c=true,CadenceType__c='Type2', OwnerId=runningUser.Id);
      Lead ld7 = new Lead(LastName='Lead7', Company='Lead7', OwnerId=runningUser.Id);
      Lead[] lds = new Lead[]{ld5,ld6,ld7};
      TriggerMethods.SKIP_TRIGGERS=true;
      insert lds;
      TriggerMethods.SKIP_TRIGGERS=false;
       
      Cadence__c cad1 = new Cadence__c(Name='Cadence1',Active__c=true,Cadence_Type__c='Type1');
      Cadence__c cad2 = new Cadence__c(Name='Cadence2',Active__c=true,Cadence_Type__c='Type2');
      Cadence__c cad3 = new Cadence__c(Name='Cadence3',Active__c=true,Cadence_Type__c='Type3',SetOwnerHoldout__c=33);
      Cadence__c[] cads = new Cadence__c[]{cad1,cad2,cad3};
      insert cads;
       
      Cadence_Step__c cadStep1a = new Cadence_Step__c(Name='Step 1a', CadenceId__c = cad1.Id, Touchpoint_Type__c = 'Call',Step_Number__c = 1);
      Cadence_Step__c cadStep1b = new Cadence_Step__c(Name='Step 1b', CadenceId__c = cad1.Id, Touchpoint_Type__c = 'Call',Step_Number__c = 2);
      Cadence_Step__c cadStep2a = new Cadence_Step__c(Name='Step 2a', CadenceId__c = cad2.Id, Touchpoint_Type__c = 'Call',Step_Number__c = 1);
      Cadence_Step__c cadStep2b = new Cadence_Step__c(Name='Step 2b', CadenceId__c = cad2.Id, Touchpoint_Type__c = 'Call',Step_Number__c = 2);
      Cadence_Step__c cadStep3a = new Cadence_Step__c(Name='Step 3a', CadenceId__c = cad3.Id, Touchpoint_Type__c = 'Call',Step_Number__c = 1);
      Cadence_Step__c cadStep3b = new Cadence_Step__c(Name='Step 3b', CadenceId__c = cad3.Id, Touchpoint_Type__c = 'Call',Step_Number__c = 2);
      Cadence_Step__c[] steps = new Cadence_Step__c[]{cadStep1a,cadStep1b,cadStep2a,cadStep2b,cadStep3a,cadStep3b};
      insert steps;
      
      // to test hold out/ownership change
      User usr = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 1];
       
      Cadence_Assignment_Record__c car1a = new Cadence_Assignment_Record__c(Name='CAR1a',Cadence__c=cad1.Id, Status__c='Open'
                                                                     ,CadenceObject__c=acct1.Id, Cadence_Owner__c=usr.Id);
      Cadence_Assignment_Record__c car1b = new Cadence_Assignment_Record__c(Name='CAR1b',Cadence__c=cad2.Id, Status__c='Open'
                                                                     ,CadenceObject__c=acct1.Id, Cadence_Owner__c=usr.Id);
      Cadence_Assignment_Record__c car1c = new Cadence_Assignment_Record__c(Name='CAR1c',Cadence__c=cad3.Id, Status__c='Open'
                                                                     ,CadenceObject__c=acct1.Id, Cadence_Owner__c=usr.Id);
      Cadence_Assignment_Record__c car2a = new Cadence_Assignment_Record__c(Name='CAR2a',Cadence__c=cad1.Id, Status__c='Open'
                                                                     ,CadenceObject__c=acct2.Id, Cadence_Owner__c=usr.Id);
      Cadence_Assignment_Record__c car2b = new Cadence_Assignment_Record__c(Name='CAR2b',Cadence__c=cad2.Id, Status__c='Open'
                                                                     ,CadenceObject__c=acct2.Id, Cadence_Owner__c=usr.Id);
      Cadence_Assignment_Record__c car3a = new Cadence_Assignment_Record__c(Name='CAR3a',Cadence__c=cad3.Id, Status__c='Open'
                                                                     ,CadenceObject__c=acct3.Id, Cadence_Owner__c=usr.Id);
       
      Cadence_Assignment_Record__c car5a = new Cadence_Assignment_Record__c(Name='CAR5a',Cadence__c=cad1.Id, Status__c='Open'
                                                                     ,CadenceObject__c=ld5.Id, Cadence_Owner__c=usr.Id);
      Cadence_Assignment_Record__c car6a = new Cadence_Assignment_Record__c(Name='CAR6a',Cadence__c=cad1.Id, Status__c='Open'
                                                                     ,CadenceObject__c=ld6.Id, Cadence_Owner__c=usr.Id);
      Cadence_Assignment_Record__c car6b = new Cadence_Assignment_Record__c(Name='CAR6b',Cadence__c=cad2.Id, Status__c='Open'
                                                                     ,CadenceObject__c=ld6.Id, Cadence_Owner__c=usr.Id);
      Cadence_Assignment_Record__c car7a = new Cadence_Assignment_Record__c(Name='CAR7a',Cadence__c=cad3.Id, Status__c='Open'
                                                                     ,CadenceObject__c=ld7.Id, Cadence_Owner__c=usr.Id);
       
      Cadence_Assignment_Record__c[] cars = new Cadence_Assignment_Record__c[]{car1a,car1b,car1c,car2a,car2b,car3a,car5a,car6a,car6b,car7a};
      Test.startTest();
      insert cars;
      Test.stopTest();
      
      Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, OwnerId, Name, In_Cadence__c, CadenceType__c, LastCadenceClosedDate__c, LastCadenceClosedType__c, LastCadenceName__c
                                                           ,Hold_Out__c, Hold_Out_Expiration__c, Permanent_Hold_Out_Description__c
                                                       from Account]);
      acct1 = acctMap.get(acct1.Id);
      System.assertEquals(true,acct1.In_Cadence__c);
      System.assertEquals('Type1,Type2,Type3',acct1.CadenceType__c);
      System.assertEquals(runningUser.Id,acct1.OwnerId);
      System.assertEquals(false,acct1.Hold_Out__c);
      acct2 = acctMap.get(acct2.Id);
      System.assertEquals(true,acct2.In_Cadence__c);
      System.assertEquals('Type1,Type2',acct2.CadenceType__c);
      System.assertEquals(runningUser.Id,acct2.OwnerId);
      System.assertEquals(false,acct2.Hold_Out__c);
      acct3 = acctMap.get(acct3.Id);
      System.assertEquals(true,acct3.In_Cadence__c);
      System.assertEquals('Type3',acct3.CadenceType__c);
      System.assertEquals('Cadence3',acct3.LastCadenceName__c);
      System.assertEquals(usr.Id,acct3.OwnerId);
      System.assertEquals(true,acct3.Hold_Out__c);
      System.assertEquals(Date.today().addDays(33),acct3.Hold_Out_Expiration__c);
      System.assertEquals(CadenceQueueable.OWNER_HOLD_OUT_REASON,acct3.Permanent_Hold_Out_Description__c);
       
      Map<Id,Lead> ldMap = new Map<Id,Lead>([Select Id, OwnerId, Name, In_Cadence__c, CadenceType__c, LastCadenceClosedDate__c, LastCadenceClosedType__c, LastCadenceName__c 
                                                   ,Hold_Out__c, Hold_Out_Expiration__c, Hold_Out_Reason__c
                                               from Lead]);
      ld5 = ldMap.get(ld5.Id);
     
      System.assertEquals(true,ld5.In_Cadence__c);
      System.assertEquals('Type1',ld5.CadenceType__c);
      System.assertEquals('Cadence1',ld5.LastCadenceName__c);
      System.assertEquals(runningUser.Id,ld5.OwnerId);
      System.assertEquals(false,ld5.Hold_Out__c);
      ld6 = ldMap.get(ld6.Id);
      System.assertEquals(true,ld6.In_Cadence__c);
      System.assertEquals('Type1,Type2',ld6.CadenceType__c);
      //System.assertEquals('Cadence2',ld6.LastCadenceName__c);
      // because they're inserted at the same time, we can't depend on order.
      System.assertEquals(true,(ld6.LastCadenceName__c == 'Cadence2' || ld6.LastCadenceName__c == 'Cadence1'));
      System.assertEquals(runningUser.Id,ld6.OwnerId);
      System.assertEquals(false,ld6.Hold_Out__c);
      ld7 = ldMap.get(ld7.Id);
      System.assertEquals(true,ld7.In_Cadence__c);
      System.assertEquals('Type3',ld7.CadenceType__c);
      System.assertEquals(usr.Id,ld7.OwnerId);
      System.assertEquals(true,ld7.Hold_Out__c);
      System.assertEquals(Date.today().addDays(33),ld7.Hold_Out_Expiration__c);
      System.assertEquals(CadenceQueueable.OWNER_HOLD_OUT_REASON,ld7.Hold_Out_Reason__c);
       
      CadenceQueueable.queueableLaunched=false;
      CadenceQueueable.RUN_INLINE=true;
      car1b.Status__c='Closed';
      car2a.Status__c='Closed';
      car3a.Status__c='Closed';
      car3a.CloseReason__c='Testing Closed';
      car6a.Status__c='Closed';
      car7a.Status__c='Closed';
      cars = new Cadence_Assignment_Record__c[]{car1b,car2a,car3a,car6a,car7a};
      update cars;
       
      acctMap = new Map<Id,Account>([Select Id, Name, In_Cadence__c, CadenceType__c, EvaluateCadence__c, LastCadenceClosedDate__c, LastCadenceClosedType__c from Account]);
      acct1 = acctMap.get(acct1.Id);
      System.assertEquals(true,acct1.In_Cadence__c);
      System.assertEquals('Type1,Type3',acct1.CadenceType__c);
      acct2 = acctMap.get(acct2.Id);
      System.assertEquals(true,acct2.In_Cadence__c);
      System.assertEquals('Type2',acct2.CadenceType__c);
      acct3 = acctMap.get(acct3.Id);
      System.assertEquals(false,acct3.In_Cadence__c);
      System.assertEquals(null,acct3.CadenceType__c);
      System.assertEquals(Date.today(),acct3.LastCadenceClosedDate__c);
      System.assertEquals('Type3',acct3.LastCadenceClosedType__c);
       
      ldMap = new Map<Id,Lead>([Select Id, Name, In_Cadence__c, CadenceType__c, EvaluateCadence__c, LastCadenceClosedDate__c, LastCadenceClosedType__c from Lead]);
      ld5 = ldMap.get(ld5.Id);
      System.assertEquals(true,ld5.In_Cadence__c);
      System.assertEquals('Type1',ld5.CadenceType__c);
      ld6 = ldMap.get(ld6.Id);
      System.assertEquals(true,ld6.In_Cadence__c);
      System.assertEquals('Type2',ld6.CadenceType__c);
      ld7 = ldMap.get(ld7.Id);
      System.assertEquals(false,ld7.In_Cadence__c);
      System.assertEquals(null,ld7.CadenceType__c);
      
      // clear the fields
      acct1.In_Cadence__c=false;
      acct1.CadenceType__c=null;
      acct2.In_Cadence__c=false;
      acct2.CadenceType__c=null;
      acct3.In_Cadence__c=false;
      acct3.CadenceType__c=null;
      update acctMap.values();
      
      ld5.In_Cadence__c=false;
      ld5.CadenceType__c=null;
      ld6.In_Cadence__c=false;
      ld6.CadenceType__c=null;
      ld7.In_Cadence__c=false;
      ld7.CadenceType__c=null;
      update ldMap.values();

      // verify all are cleared
      acctMap = new Map<Id,Account>([Select Id, Name, In_Cadence__c, CadenceType__c, EvaluateCadence__c, LastCadenceClosedDate__c, LastCadenceClosedType__c from Account]);
      acct1 = acctMap.get(acct1.Id);
      System.assertEquals(false,acct1.In_Cadence__c);
      System.assertEquals(null,acct1.CadenceType__c);
      acct2 = acctMap.get(acct2.Id);
      System.assertEquals(false,acct2.In_Cadence__c);
      System.assertEquals(null,acct2.CadenceType__c);
      acct3 = acctMap.get(acct3.Id);
      System.assertEquals(false,acct3.In_Cadence__c);
      System.assertEquals(null,acct3.CadenceType__c);
       
      ldMap = new Map<Id,Lead>([Select Id, Name, In_Cadence__c, CadenceType__c, EvaluateCadence__c, LastCadenceClosedDate__c, LastCadenceClosedType__c from Lead]);
      ld5 = ldMap.get(ld5.Id);
      System.assertEquals(false,ld5.In_Cadence__c);
      System.assertEquals(null,ld5.CadenceType__c);
      ld6 = ldMap.get(ld6.Id);
      System.assertEquals(false,ld6.In_Cadence__c);
      System.assertEquals(null,ld6.CadenceType__c);
      ld7 = ldMap.get(ld7.Id);
      System.assertEquals(false,ld7.In_Cadence__c);
      System.assertEquals(null,ld7.CadenceType__c);
      
      // make sure the triggers fire
      ZipCheckOwner.SKIP_TRIGGERS=false;
      TriggerMethods.clearVariables();
      
      acct1.EvaluateCadence__c=true;
      acct2.EvaluateCadence__c=true;
      acct3.EvaluateCadence__c=true;

      ld5.EvaluateCadence__c=true;
      ld6.EvaluateCadence__c=true;
      ld7.EvaluateCadence__c=true;
      
      update acctMap.values();
      TriggerMethods.clearVariables();
      System.debug('testCarUpdates before final ldMap update');
      update ldMap.values();
      
      acctMap = new Map<Id,Account>([Select Id, Name, In_Cadence__c, CadenceType__c, EvaluateCadence__c, LastCadenceClosedDate__c, LastCadenceClosedType__c from Account]);
      acct1 = acctMap.get(acct1.Id);
      System.assertEquals(true,acct1.In_Cadence__c);
      System.assertEquals('Type1,Type3',acct1.CadenceType__c);
      System.assertEquals(false,acct1.EvaluateCadence__c);
      acct2 = acctMap.get(acct2.Id);
      System.assertEquals(true,acct2.In_Cadence__c);
      System.assertEquals('Type2',acct2.CadenceType__c);
      System.assertEquals(false,acct2.EvaluateCadence__c);
      acct3 = acctMap.get(acct3.Id);
      System.assertEquals(false,acct3.In_Cadence__c);
      System.assertEquals(null,acct3.CadenceType__c);
      System.assertEquals(false,acct3.EvaluateCadence__c);
       
      ldMap = new Map<Id,Lead>([Select Id, Name, In_Cadence__c, CadenceType__c, EvaluateCadence__c, LastCadenceClosedDate__c, LastCadenceClosedType__c from Lead]);
      ld5 = ldMap.get(ld5.Id);
      System.assertEquals(true,ld5.In_Cadence__c);
      System.assertEquals('Type1',ld5.CadenceType__c);
      System.assertEquals(false,ld5.EvaluateCadence__c);
      ld6 = ldMap.get(ld6.Id);
      System.assertEquals(true,ld6.In_Cadence__c);
      System.assertEquals('Type2',ld6.CadenceType__c);
      System.assertEquals(false,ld6.EvaluateCadence__c);
      ld7 = ldMap.get(ld7.Id);
      System.assertEquals(false,ld7.In_Cadence__c);
      System.assertEquals(null,ld7.CadenceType__c);
      System.assertEquals(false,ld7.EvaluateCadence__c);
 
   } // testCarUpdates
    
   static testMethod void testReferralAccount() {
      User runningUser = UserHelper.getRunningUser();
      Referral_Account__c acct1 = new Referral_Account__c(Name='Acct1', OwnerId=runningUser.Id);
      Referral_Account__c acct2 = new Referral_Account__c(Name='Acct2', OwnerId=runningUser.Id);
      Referral_Account__c acct3 = new Referral_Account__c(Name='Acct3', OwnerId=runningUser.Id);
      ReferralAccountMethods.SKIP_TRIGGERS=true; 
      Referral_Account__c[] accts = new Referral_Account__c[]{acct1,acct2,acct3};
      insert accts;
       
      Cadence__c cad = CadenceUpdateTest.getTestCadence();
       
      User usr = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 1];
       
      Cadence_Assignment_Record__c car1 = new Cadence_Assignment_Record__c(Name='CAR1',Cadence__c=cad.Id, Status__c='Open'
                                                                     ,CadenceObject__c=acct1.Id, Cadence_Owner__c=usr.Id);
      Cadence_Assignment_Record__c car2 = new Cadence_Assignment_Record__c(Name='CAR2',Cadence__c=cad.Id, Status__c='Open'
                                                                     ,CadenceObject__c=acct2.Id, Cadence_Owner__c=usr.Id);
      Cadence_Assignment_Record__c car3 = new Cadence_Assignment_Record__c(Name='CAR3',Cadence__c=cad.Id, Status__c='Open'
                                                                     ,CadenceObject__c=acct3.Id, Cadence_Owner__c=usr.Id);
      Cadence_Assignment_Record__c[] cars = new Cadence_Assignment_Record__c[]{car1,car2,car3};
      Test.startTest();
      insert cars;
      Test.stopTest();
      
      Map<Id,Referral_Account__c> acctMap = new Map<Id,Referral_Account__c>([Select Id, OwnerId, Name, CadenceType__c, In_Cadence__c, LastCadenceClosedDate__c, LastCadenceClosedReason__c
                                                           ,Hold_Out__c, Hold_Out_Reason__c
                                                       from Referral_Account__c]);
      acct1 = acctMap.get(acct1.Id);
      System.assertEquals(true,acct1.In_Cadence__c);
      System.assertEquals('Payroll',acct1.CadenceType__c);
      acct2 = acctMap.get(acct2.Id);
      System.assertEquals(true,acct2.In_Cadence__c);
      System.assertEquals('Payroll',acct2.CadenceType__c);
      acct3 = acctMap.get(acct3.Id);
      System.assertEquals(true,acct3.In_Cadence__c);
      System.assertEquals('Payroll',acct3.CadenceType__c);

      CadenceQueueable.queueableLaunched=false;
      CadenceQueueable.RUN_INLINE=true;
      car1.Status__c='Closed';
      car1.Close_Date__c=Date.today();
      car1.CloseReason__c='It was time to close';
      car3.Status__c='Closed';
      car3.Close_Date__c=Date.today();
      car3.CloseReason__c='It was time to close';
      cars = new Cadence_Assignment_Record__c[]{car1,car3};
      update cars;

      acctMap = new Map<Id,Referral_Account__c>([Select Id, OwnerId, Name, CadenceType__c, In_Cadence__c, LastCadenceClosedDate__c, LastCadenceClosedReason__c
                                                           ,Hold_Out__c, Hold_Out_Reason__c
                                                       from Referral_Account__c]);
      acct1 = acctMap.get(acct1.Id);
      System.debug('acct1='+acct1);
      System.assertEquals(false,acct1.In_Cadence__c);
      System.assertEquals(null,acct1.CadenceType__c);
      System.assertEquals(Date.today(),acct1.LastCadenceClosedDate__c);
      acct2 = acctMap.get(acct2.Id);
      System.assertEquals(true,acct2.In_Cadence__c);
      System.assertEquals('Payroll',acct2.CadenceType__c);
      acct3 = acctMap.get(acct3.Id);
      System.assertEquals(false,acct3.In_Cadence__c);
      System.assertEquals(null,acct3.CadenceType__c);
      System.assertEquals(Date.today(),acct3.LastCadenceClosedDate__c);
       
      acct2.In_Cadence__c=false;
      acct2.CadenceType__c=null;
      update acct2;
       
      acctMap = new Map<Id,Referral_Account__c>([Select Id, OwnerId, Name, CadenceType__c, In_Cadence__c, LastCadenceClosedDate__c, LastCadenceClosedReason__c
                                                           ,Hold_Out__c, Hold_Out_Reason__c
                                                       from Referral_Account__c]);
      acct2 = acctMap.get(acct2.Id);
      System.assertEquals(false,acct2.In_Cadence__c);
      System.assertEquals(null,acct2.CadenceType__c);

      TriggerMethods.clearVariables();
      acct2.EvaluateCadence__c=true;
      ReferralAccountMethods.SKIP_TRIGGERS=false;
      update acct2;
       
      acctMap = new Map<Id,Referral_Account__c>([Select Id, OwnerId, Name, CadenceType__c, In_Cadence__c, LastCadenceClosedDate__c, LastCadenceClosedReason__c
                                                           ,Hold_Out__c, Hold_Out_Reason__c
                                                       from Referral_Account__c]);
      acct2 = acctMap.get(acct2.Id);
      System.assertEquals(true,acct2.In_Cadence__c);
      System.assertEquals('Payroll',acct2.CadenceType__c);

   } // testReferralAccount
    
} // class CadenceQueueableTest