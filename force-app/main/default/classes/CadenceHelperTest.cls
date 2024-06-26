/* Test Methods for CadenceHelper

 * History
 * -------
  09/05/2019 Dan Carmen           Created
  02/28/2020 Dan Carmen           Add additional criteria to match opp to touchpoint
  10/21/2021 Dan Carmen           Fix cache setting
  11/17/2021 Dan Carmen           Add debugging
  12/29/2021 Dan Carmen           Add CadenceTypeGroup__c to check for opportunity match
  06/21/2022 Dan Carmen           Clone steps when Cadence cloned
  08/17/2022 Dan Carmen           Change for setting the Close Reason on referring opps
  12/10/2022 Dan Carmen           Added ability to match an opp to a cadence based ONLY on opportunity type
  01/24/2023 Dan Carmen           Update to checkTouchpoint to save the latest touchpoint 

*/
@isTest
public class CadenceHelperTest {
   @testSetup
   public static void setupData() {
      TriggerMethodsTest.createTriggerSetting('AccountBefore', true, false, false, false,new String[]{'CadenceHelper'});
      TriggerMethodsTest.createTriggerSetting('LeadBefore', true, false, false, false,new String[]{'CadenceHelper'});
      TriggerMethodsTest.createTriggerSetting('OpptyBefore', true, false, false, false,new String[]{'CadenceHelper'});
      TriggerMethodsTest.createTriggerSetting('OpptyAfter', false, true, false, false,new String[]{'CadenceHelper'});
      TriggerMethodsTest.createTriggerSetting('CadenceTrigger', true, true, false, false,new String[]{'CadenceHelper'});
      TriggerMethodsTest.createTriggerSetting('ReferralAccountBefore', true, false, false, false, new String[]{'CadenceHelper'});
      TriggerMethodsTest.createTriggerSetting('ReferralAccountAfter', false, true, false, false, new String[]{'CadenceHelper'});
      TriggerMethodsTest.saveSetupClasses();

      CadenceUpdateTest.setupTestCadence();
   } // setupData

   static testMethod void testOppLinking() {
      Account acct = new Account(Name='Test Account');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
       
      Contact ctct = new Contact(AccountId=acct.Id, LastName='ContactLast', Sales_Contact__c=true);
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = true;
      insert ctct;
      
      acct.SignificantContact__c = ctct.Id;
      update acct;
       
      Cadence__c cadence = CadenceUpdateTest.getTestCadence();
      Cadence__c updateCad = new Cadence__c(Id=cadence.Id, MatchReferringOpp__c=true);
      update updateCad;
      updateCad = [Select Id, Name, OppMatchesCarCloseReason__c from Cadence__c where Id=:cadence.Id];
       
      Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c();
      testCar.CadenceObject__c = acct.Id;
      testCar.Cadence__c = cadence.Id;
      testCar.Cadence_Owner__c = UserInfo.getUserId();
      testCar.Sales_Program__c='A Really Cool Program';
      insert testCar;
      Cadence_Touchpoint__c[] touchpoints = CadenceUpdateTest.getTouchpoints(cadence.Id);
      System.assertEquals(1,touchpoints.size());
      Test.startTest();

       
      Opportunity referringOpp = new Opportunity(AccountId=acct.Id, OwnerId=UserInfo.getUserId(), Name='TestOpp', CloseDate=Date.today(), StageName='Pending', OpportunityType__c=Label.OppType_Referral);
      // skip triggers for this opp
      //OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
      insert referringOpp;
      //OpptyMethods.SKIP_OPPTY_TRIGGERS=false;
      
       /*
      Referral__c ref = new Referral__c(Name='Test ref', Account__c=acct.Id, Referring_Opportunity__c=referringOpp.Id);
      // we don't need the trigger to fire for this.
      ReferralTriggerActions.SKIP_TRIGGER=true;
      insert ref;
      
       
      Opportunity opp = new Opportunity(AccountId=acct.Id, OwnerId=UserInfo.getUserId(), Name='TestOpp', CloseDate=Date.today(), StageName='Pending',LeadSource='Self Generated',LeadSourceCategory__c='Self Generated'
                                        ,OpportunityType__c='Payroll', ReferralLookup__c=ref.Id);
      insert opp;
       */
      Test.stopTest();
       
      touchpoints = CadenceUpdateTest.getTouchpoints(cadence.Id);
      System.assertEquals(1,touchpoints.size());
      System.assertEquals(referringOpp.Id, touchpoints[0].OpportunityId__c);
      System.assertEquals(Date.today(), touchpoints[0].Close_Date__c);
      
      Cadence_Assignment_Record__c checkCar = touchpoints[0].CarRecord__r;
      System.assertEquals(true, checkCar.Closed__c);
      System.assertEquals(true, checkCar.Rep_Closed__c);
      System.assertEquals(updateCad.OppMatchesCarCloseReason__c, checkCar.CloseReason__c);
      System.assertEquals(touchpoints[0].Id, checkCar.LatestTouchpoint__c);
      System.assertEquals(1, checkCar.NbrOfTouchpoints__c);
       
      Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([Select Id, Name, Cadence_Touchpoint__c, Field_Campaign__c
                                                                  ,ReferralLookup__c
                                                                  ,ReferralLookup__r.Id, ReferralLookup__r.Cadence_Touchpoint__c
                                                              From Opportunity]);
      Opportunity checkRefOpp = oppMap.get(referringOpp.Id);
      System.assertEquals(touchpoints[0].Id, checkRefOpp.Cadence_Touchpoint__c);
      System.assertEquals(testCar.Sales_Program__c, checkRefOpp.Field_Campaign__c);
      /*
      Opportunity checkSelOpp = oppMap.get(opp.Id);
      System.assertEquals(touchpoints[0].Id, checkSelOpp.Cadence_Touchpoint__c);
      System.assertEquals(testCar.Sales_Program__c, checkSelOpp.Field_Campaign__c);
      System.assertEquals(touchpoints[0].Id, checkSelOpp.ReferralLookup__r.Cadence_Touchpoint__c);
      */
   } // testOppLinking
   
   static testMethod void testGetCadence() {
      Cadence__c cadence = CadenceUpdateTest.getTestCadence();
      Set<Id> cadenceIdSet = new Set<Id>{cadence.Id};
      Map<Id,Cadence__c> cadenceMap = CadenceHelper.getCadences(cadenceIdSet);
      System.assertEquals(true,cadenceMap.containsKey(cadence.Id));
      
      
   } // testGetCadence

   static testMethod void testUniqueName() {
      Cadence__c cad = new Cadence__c(Name='This is a test', Cadence_Type__c='Payroll', Active__c=true);
      insert cad;
      
      Cadence_Step__c step1 = new Cadence_Step__c(Name='Email Step1', Touchpoint_Type__c='Email', Step_Number__c=1, CadenceId__c=cad.Id);
      Cadence_Step__c step2 = new Cadence_Step__c(Name='Email Step1', Touchpoint_Type__c='Email', Step_Number__c=2, CadenceId__c=cad.Id);
      Cadence_Step__c[] steps = new Cadence_Step__c[]{step1,step2};
      try {
         insert steps;
         System.assertEquals(1,2,'We should not get here!');
      } catch (Exception e) {
         System.assertEquals(true,e.getMessage().contains('is used more than once for this Cadence'));
      }
      
      TriggerMethods.clearVariables();
      insert step1;
      
      TriggerMethods.clearVariables();
      System.debug('testUniqueName before inserting step2');
      try {
         insert step2;
         System.assertEquals(1,2,'We should also not get here!');
      } catch (Exception e) {
         System.assertEquals(true,e.getMessage().contains('already exists for this Cadence!'));
      }
   } // testUniqueName
    
   static testMethod void testMisc() {
      Account acct = new Account(Name='Test Account');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
      ZipCheckOwner.SKIP_TRIGGERS=false;
      acct.EvaluateCadence__c=true;
      update acct;
      acct = [Select Id, Name, EvaluateCadence__c from Account where Id=:acct.Id];
      System.assertEquals(false,acct.EvaluateCadence__c);
       
      Lead ld = new Lead(LastName='Harrison', Company='Test Company');
      TriggerMethods.SKIP_TRIGGERS=true;
      insert ld;
      TriggerMethods.SKIP_TRIGGERS=false;
      ld.EvaluateCadence__c = true;
      update ld;
      ld = [Select Id, EvaluateCadence__c from Lead where Id=:ld.Id];
      System.assertEquals(false,ld.EvaluateCadence__c);
   } // testMisc
    
   static testMethod void testEmailTemplates() {
      // select some email templates for testing
      EmailTemplate[] templates = [Select Id, Name from EmailTemplate limit 3];
      Cadence__c cad = new Cadence__c(Name='Test Cadence', Active__c=true,Cadence_Type__c='Payroll' );
      insert cad;
      // an invalid id.
      Cadence_Step__c step1 = new Cadence_Step__c(CadenceId__c=cad.Id, Name='Step1', Step_Number__c=1, Touchpoint_Type__c='Email', EmailTemplateIds__c='badId' );
      try {
         insert step1;
         System.assertEquals(1,2,'We should not get here 1!');
      } catch (Exception e) {
         System.assertEquals(true,e.getMessage().contains('is not a valid Id'));
      }
      System.debug('testEmailTemplates attempt to insert a non-template id');
      // an id that isn't an email template id
      step1.EmailTemplateIds__c=cad.Id;
      TriggerMethods.clearVariables();
      try {
         insert step1;
         System.assertEquals(1,2,'We should not get here 2!');
      } catch (Exception e) {
         System.assertEquals(true,e.getMessage().contains('Could not find template for'));
      }
      System.debug('testEmailTemplates attempt to insert a valid template id');
      // with a valid id
      step1.EmailTemplateIds__c = templates[0].Id;
      TriggerMethods.clearVariables();
      insert step1;
      step1 = [Select Id, EmailTemplateIds__c, EmailTemplateNames__c from Cadence_Step__c where id=:step1.Id];
      System.assertEquals(step1.EmailTemplateNames__c, templates[0].Name);

      System.debug('testEmailTemplates 1 good id and 1 bad id');
      Cadence_Step__c step2 = new Cadence_Step__c(CadenceId__c=cad.Id, Name='Step2', Step_Number__c=2, Touchpoint_Type__c='Email' );
      step2.EmailTemplateIds__c=cad.Id+','+templates[0].Id;
      TriggerMethods.clearVariables();
      try {
         insert step2;
         System.assertEquals(1,2,'We should not get here 2!');
      } catch (Exception e) {
         System.assertEquals(true,e.getMessage().contains('Could not find template for'));
      }
 
      System.debug('testEmailTemplates 3 good ids');
      step2.EmailTemplateIds__c=templates[0].Id+','+templates[1].Id+','+templates[2].Id;
      TriggerMethods.clearVariables();
      insert step2;
      step2 = [Select Id, EmailTemplateIds__c, EmailTemplateNames__c from Cadence_Step__c where id=:step2.Id];
      System.assertEquals(templates[0].Name+','+ templates[1].Name+','+ templates[2].Name, step2.EmailTemplateNames__c);

   } // testEmailTemplates
    
   static testMethod void testDeleteStep() {
      Cadence__c cadence = CadenceUpdateTest.getTestCadence();
      // Cadence_Steps__r
      Cadence_Step__c step1 = cadence.Cadence_Steps__r[0];
      Cadence_Touchpoint__c tp = new Cadence_Touchpoint__c(Name='test touchpoint', Cadence_Touchpoint_Step__c=step1.Id);
      insert tp;
       
      System.assertEquals(3,[select count() from Cadence_Step__c where CadenceId__c=:cadence.Id] );
      // delete should fail because there's a touchpoint attached
      Boolean deleteFailed=false;
      try {
         delete step1;
         System.assertEquals(1,2,'Should not be allowed to delete the step!');
      } catch (Exception e) {
         deleteFailed=true;
      }
      System.assertEquals(true,deleteFailed);
      // should still be 3
      System.assertEquals(3,[select count() from Cadence_Step__c where CadenceId__c=:cadence.Id] );
      
      // delete the touchpoint - now should be able to delete the step
      delete tp;
      delete step1;
      // now should be only 2
      System.assertEquals(2,[select count() from Cadence_Step__c where CadenceId__c=:cadence.Id] );

   } // testDeleteStep
    
   static testMethod void testOngoingCadence() {
      Cadence__c cad1 = new Cadence__c(Name='Test Ongoing1', Cadence_Type__c='Payroll', Active__c=true, TargetType__c='Ongoing Referral Source', ReferralSourceBusinessType2__c='Accounting Firm'
                                     ,ReferralType__c='Bronze'
                                     ,CPARotation__c='Monthly');
      Cadence__c cad2 = new Cadence__c(Name='Test Ongoing2', Cadence_Type__c='Payroll', Active__c=true, TargetType__c='Ongoing Referral Source', ReferralSourceBusinessType2__c='Accounting Firm'
                                     ,ReferralType__c='Bronze'
                                     ,CPARotation__c='Weekly');
      Cadence__c[] cads = new Cadence__c[]{cad1,cad2};
      insert cads;
      
      Cadence_Step__c step1a = new Cadence_Step__c(Name='Email Step1', Touchpoint_Type__c='Email', Step_Number__c=1, CadenceId__c=cad1.Id, WeekStart__c='1',WeekEnd__c='2');
      Cadence_Step__c step1b = new Cadence_Step__c(Name='Email Step2', Touchpoint_Type__c='Email', Step_Number__c=2, CadenceId__c=cad1.Id, WeekStart__c='3',WeekEnd__c='4');
      Cadence_Step__c step2a = new Cadence_Step__c(Name='Email Step3', Touchpoint_Type__c='Email', Step_Number__c=1, CadenceId__c=cad2.Id, WeekStart__c='1',WeekEnd__c='2');
      Cadence_Step__c step2b = new Cadence_Step__c(Name='Email Step4', Touchpoint_Type__c='Email', Step_Number__c=2, CadenceId__c=cad2.Id, WeekStart__c='3',WeekEnd__c='4');
      Cadence_Step__c[] steps = new Cadence_Step__c[]{step1a,step1b,step2a,step2b};
      insert steps;
       
      Referral_Account__c refAcct1 = new Referral_Account__c(Name='acct1', Referral_Source_Business_Type__c='Other', Referral_Type__c=null, Group__c=null);
      Referral_Account__c refAcct2 = new Referral_Account__c(Name='acct2', Referral_Source_Business_Type__c='Accounting Firm', Referral_Type__c='Bronze', Group__c='Weekly');
      Referral_Account__c refAcct3 = new Referral_Account__c(Name='acct3', Referral_Source_Business_Type__c='Accounting Firm', Referral_Type__c='Bronze', Group__c='Monthly');
      Referral_Account__c refAcct4 = new Referral_Account__c(Name='acct3', Referral_Source_Business_Type__c='Accounting Firm', Referral_Type__c='Silver', Group__c='Monthly');
      Referral_Account__c[] refAccts = new Referral_Account__c[]{refAcct1,refAcct2,refAcct3,refAcct4};
      System.debug('testOngoingCadence before insert');
      insert refAccts;
       
      System.assertEquals(2,[select count() from Cadence_Assignment_Record__c where ReferralAccount__c in :refAccts]);
      System.assertEquals(0,[select count() from Cadence_Assignment_Record__c where ReferralAccount__c=:refAcct1.Id]);
      System.assertEquals(1,[select count() from Cadence_Assignment_Record__c where ReferralAccount__c=:refAcct2.Id and Cadence__c=:cad2.Id and Status__c='Open']);
      System.assertEquals(1,[select count() from Cadence_Assignment_Record__c where ReferralAccount__c=:refAcct3.Id and Cadence__c=:cad1.Id and Status__c='Open']);
      System.assertEquals(0,[select count() from Cadence_Assignment_Record__c where ReferralAccount__c=:refAcct4.Id]);
      
      refAcct1.Referral_Source_Business_Type__c = 'Accounting Firm';
      refAcct1.Referral_Type__c = 'Bronze';
      refAcct1.Group__c = 'Weekly';
      refAcct2.Group__c='Monthly'; 
      refAcct3.Group__c='Daily';
      refAcct4.Referral_Type__c='Bronze';
      TriggerMethods.clearVariables();
      update refAccts;
       
      System.assertEquals(5,[select count() from Cadence_Assignment_Record__c where ReferralAccount__c in :refAccts]);
      System.assertEquals(1,[select count() from Cadence_Assignment_Record__c where ReferralAccount__c=:refAcct1.Id and Cadence__c=:cad2.Id and Status__c='Open']);
       
      System.assertEquals(1,[select count() from Cadence_Assignment_Record__c where ReferralAccount__c=:refAcct2.Id and Cadence__c=:cad1.Id and Status__c='Open']);
      System.assertEquals(1,[select count() from Cadence_Assignment_Record__c where ReferralAccount__c=:refAcct2.Id and Cadence__c=:cad2.Id and Status__c='Closed']);
       
      System.assertEquals(1,[select count() from Cadence_Assignment_Record__c where ReferralAccount__c=:refAcct3.Id and Cadence__c=:cad1.Id and Status__c='Closed']);
       
      System.assertEquals(1,[select count() from Cadence_Assignment_Record__c where ReferralAccount__c=:refAcct4.Id and Cadence__c=:cad1.Id and Status__c='Open']);
       
      
   } // testOngoingCadence
    
   static testMethod void testSendToPartnerFlds() {
      Group grp1 = new Group(Name='Cue Ball 1',Type='Queue');
      Group grp2 = new Group(Name='Cue Ball 2',Type='Queue');
      insert new Group[]{grp1,grp2};
      
      // set up 1 assignment groups
      Assignment_Group_Name__c agn1 = new Assignment_Group_Name__c(Name=grp1.Name,Use_Scheduler__c=true,Use_Weighting__c=true);
      insert new Assignment_Group_Name__c[]{agn1};
      
      Assignment_Group_Queues__c agq1 = new Assignment_Group_Queues__c(Name=grp1.Name, QueueId__c=grp1.Id, Assignment_Group_Name__c=agn1.Id); 
      insert new Assignment_Group_Queues__c[]{agq1};
          
      Cadence__c cad1 = new Cadence__c(Name='Cadence1', SendToPartner__c=true, SendToPartnerQueue__c='BadQueue');
      Boolean exceptionMade=false;
      try {
         insert cad1;
         System.assertEquals(1,2,'Should not get here!');
      } catch (Exception e) {
         exceptionMade=true;
         System.assertEquals(true,e.getMessage().contains('Could not find a queue'));
      }
      System.assertEquals(true,exceptionMade);
       
      cad1.SendToPartnerQueue__c=grp2.name;
      exceptionMade=false;
      TriggerMethods.clearVariables();
      try {
         insert cad1;
         System.assertEquals(1,2,'Should not get here!');
      } catch (Exception e) {
         exceptionMade=true;
         System.assertEquals(true,e.getMessage().contains('The queue was found, but the Assignment Group setup was not found'));
      }
      System.assertEquals(true,exceptionMade);
      
      cad1.SendToPartnerQueue__c=grp1.Name;
      TriggerMethods.clearVariables();
      insert cad1;
       
      cad1 = [Select Id, Name, SendToPartnerQueue__c, SendToPartnerQueueId__c from Cadence__c where Id=:cad1.id];
      System.assertEquals(grp1.Id, cad1.SendToPartnerQueueId__c);
       
   } // testSendToPartnerFlds
    
   static testMethod void testCadenceClone() {
      Cadence__c testCadence = new Cadence__c(Name = 'TestCadence',Active__c = true,Sales_Org__c = 'MMS',Cadence_Type__c='Payroll');
      insert testCadence;
       
      Set<Id> cadIdSet = new Set<Id>();
      cadIdSet.add(testCadence.Id);
      Map<Id,Cadence__c> cadMap = CadenceHelper.getCadences(cadIdSet);
      Cadence__c testCadenceCheck = cadMap.get(testCadence.Id);
      System.assertEquals(testCadenceCheck.IsThisCloned__c, testCadenceCheck.Id);
       
      EmailTemplate et = [Select Id from EmailTemplate where TemplateType = 'Text' limit 1];
      Cadence_Step__c cadStep1 = new Cadence_Step__c(Name='Step 1',CadenceId__c = testCadence.Id,Touchpoint_Type__c = 'Email',Step_Number__c = 1,EmailTemplateIds__c = et.Id);
      Cadence_Step__c cadStep2 = new Cadence_Step__c(Name='Step 2',CadenceId__c = testCadence.Id,Touchpoint_Type__c = 'Call',Step_Number__c = 2);
      insert new Cadence_Step__c[]{cadStep1,cadStep2};
          
      CadenceHelper.SKIP_TRIGGERS=false;
      Cadence__c clonedCad = testCadenceCheck.clone(false,false,false,false);
      TriggerMethods.clearVariables();
      clonedCad.Name='ClonedTestCadence';
      System.debug('testCadenceClone before insert of clone');
      insert clonedCad;
       
      System.assertEquals(2,[Select count() from Cadence_Step__c where CadenceId__c=:clonedCad.Id]);
           


   } // testCadenceClone
        
} // class CadenceHelperTest