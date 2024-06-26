/**
 * This class contains unit tests for validating the OpptyAutoCloseEvaluation class.
 * 
 *
 * History
 * --------
  03/05/2020 Jacob Hinds       Created  
  07/22/2020 Jacob Hinds        validation rule update
  05/18/2021 	Carrie Marciano updated StageNames with OppStage labels
  10/24/2023 Dan Carmen    Rewrote code, moved logic to the oppty before trigger
  12/05/2023 Dan Carmen    Add a filter for selecting the opportunities for activity
  12/15/2023 Dan Carmen    Fix the criteria, add more logging
  01/22/2024 Dan Carmen    Fix code setting the date when it's blank
  01/31/2024 Dan Carmen    Fix code for joint opportunity
  02/21/2024 Jaipal 	   Added label for HR_Pro_Upgrade in place of ASO for Opportunity Types
  03/11/2024 Dan Carmen    Add additional debugging
  04/12/2024 Dan Carmen    Add ability to skip future methods

 */
 
@isTest
public class OpptyAutoCloseEvaluationTest {
    @testSetup
    static void setupTriggers(){
        TriggerMethodsTest.createTriggerSetting('OpptyBefore', true, false, false, false,new String[]{'OpptyAutoCloseEvaluation'});
        TriggerMethodsTest.createTriggerSetting('OpptyAfter', false, true, false, false,new String[]{'OpptyAutoCloseEvaluation'});
        TriggerMethodsTest.createTriggerSetting('TaskAfter', false, true, false, false,new String[]{'OpptyAutoCloseEvaluation'});
        TriggerMethodsTest.createTriggerSetting('EventCheckType', false, true, false, false,new String[]{'OpptyAutoCloseEvaluation'});
        TriggerMethodsTest.createTriggerSetting('ReferralTrigger', false, true, false, false,new String[]{'OpptyAutoCloseEvaluation'});
        TriggerMethodsTest.saveSetupClasses();
    } // setupTriggers
    
    static testMethod void oppNoActivityTest() {
        User smbRep = [SELECT Id FROM User WHERE isActive = true and Job_Name__c=:UserHelper.JOB_REP LIMIT 1];
        
        Account acct = new Account(Name='test account');
        insert acct;
        
        Schema.RecordTypeInfo oppRT = RecordTypeHelper.getRecordType('Core Opportunity Record Type','Opportunity');
        
        RecordType__c rtSetting =  new RecordType__c(Name=oppRT.getName(),ObjectName__c='Opportunity',OpportunityType__c='Payroll',
                                                     Sales_Org__c='PAY',RecordTypeName__c=oppRt.getName(),Opportunity_Auto_Close_Duration__c=90,Opportunity_Auto_Close_Max_Probability__c=70);
        insert rtSetting;
        
        test.startTest();
        Opportunity oppty = new Opportunity(Name='test',accountId=acct.Id,CloseDate = date.today(), OwnerId=smbRep.Id,
                                            recordTypeId=oppRt.getRecordTypeId(),StageName=Label.OppStage_Qualified,
                                            LeadSource='test',OpportunityType__c='Payroll',NSS_Source__c='Inbound');
        system.runAs(smbRep){
            insert oppty;
        }
        test.stopTest();
        
        Opportunity uOppty = [SELECT Id,Auto_Close_Date__c From Opportunity WHERE Id = :oppty.Id];
        Date checkDate = date.today().addDays((Integer)rtSetting.Opportunity_Auto_Close_Duration__c);
        system.assertEquals(checkDate,uOppty.Auto_Close_Date__c);
    }//oppNoActivity
    
    static testMethod void jointOppNoActivityTest() {
        User[] users = [Select Id From User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 2];
        User smbRep = users[0];
        User asoRep = users[1];
        Account acct = new Account(Name='test account');
        insert acct;
        
        Schema.RecordTypeInfo smbOppRT = RecordTypeHelper.getRecordType('Core Opportunity Record Type','Opportunity');
        Schema.RecordTypeInfo pasOppRT = RecordTypeHelper.getRecordType('ASO Opportunity Record Type','Opportunity');        
        RecordType__c smbRtSetting =  new RecordType__c(Name=smbOppRT.getName(),ObjectName__c='Opportunity',OpportunityType__c='Payroll',
                                                        Sales_Org__c='PAY',RecordTypeName__c=smbOppRT.getName(),Opportunity_Auto_Close_Duration__c=90,Opportunity_Auto_Close_Max_Probability__c=70
                                                       ,Extend_Number_of_Days__c=45);
        RecordType__c asoRtSetting =  new RecordType__c(Name=pasOppRT.getName(),ObjectName__c='Opportunity',OpportunityType__c= Label.HR_Pro_Upgrade,
                                                        Sales_Org__c='PAS',RecordTypeName__c=pasOppRT.getName(),Auto_Close_Joint_Only__c=true);
        insert new RecordType__c[]{smbRtSetting,asoRTSetting};
        Opportunity smbOppty = new Opportunity(Name='test SMB',accountId=acct.Id,CloseDate = date.today(),
                                            recordTypeId=smbOppRT.getRecordTypeId(),StageName=Label.OppStage_Qualified,
                                            LeadSource='test',OpportunityType__c='Payroll',NSS_Source__c='Inbound',OwnerId=smbRep.Id);
        Opportunity asoOppty = new Opportunity(Name='test ASO',accountId=acct.Id,CloseDate = date.today(),
                                            recordTypeId=pasOppRT.getRecordTypeId(),StageName=Label.OppStage_Qualified,
                                            LeadSource='test',OpportunityType__c= Label.HR_Pro_Upgrade,NSS_Source__c='Inbound',OwnerId=asoRep.Id);
        Opportunity[]opptys = new Opportunity[]{smbOppty,asoOppty};
        insert opptys;
        
        Referral__c smbReferral = new Referral__c(Selling_Opportunity__c = smbOppty.Id,OwnerId = smbRep.Id);
        Referral__c asoReferral = new Referral__c(Selling_Opportunity__c = asoOppty.Id,OwnerId = smbRep.Id);
        Referral__c[]referrals = new Referral__c[]{smbReferral,asoReferral}; 
        insert referrals;
        
        smbOppty.ReferralLookup__c = smbReferral.Id;
        asoOppty.ReferralLookup__c = asoReferral.Id;   
        update opptys;
            
        ReferralJoin__c refJoin = new ReferralJoin__c(PAS_Referral__c=asoReferral.Id,Core_Referral__c=smbReferral.Id);
        insert refJoin;
        
        TriggerMethods.clearVariables();
        test.startTest();
        //system.runAs(smbRep){        
            smbReferral.ReferralJoin__c = refJoin.Id;
            asoReferral.ReferralJoin__c = refJoin.Id;
            system.debug('OpptyAutoCloseEvaluationTest updatingReferrals');
            ReferralTriggerActions.SKIP_TRIGGER = false;
            update referrals;
        //}
        test.stopTest();
        
        Opportunity uSMBOppty = [SELECT Id,Auto_Close_Date__c From Opportunity WHERE Id = :smbOppty.Id];
        Date smbCheckDate = date.today().addDays((Integer)smbRtSetting.Opportunity_Auto_Close_Duration__c);
        system.assertEquals(smbCheckDate,uSMBOppty.Auto_Close_Date__c);
        
        Opportunity uASOOppty = [SELECT Id,Auto_Close_Date__c From Opportunity WHERE Id = :asoOppty.Id];
        system.assertEquals(uSMBOppty.Auto_Close_Date__c,uASOOppty.Auto_Close_Date__c);
    }//jointOppNoActivityTest
    
    static testMethod void oppWithTaskTest() {
        //User you = UserHelper.getRunningUser();
        //you.Sales_Org__c = 'PAY';
        //update you;

        User smbRep = [SELECT Id FROM User WHERE isActive = true and Job_Name__c=:UserHelper.JOB_REP LIMIT 1];
        
        Account acct = new Account(Name='test account');
        insert acct;
        
        Schema.RecordTypeInfo oppRT = RecordTypeHelper.getRecordType('Core Opportunity Record Type','Opportunity');
        
        RecordType__c rtSetting =  new RecordType__c(Name=oppRT.getName(),ObjectName__c='Opportunity',OpportunityType__c='Payroll',
                                                     Sales_Org__c='PAY',RecordTypeName__c=oppRt.getName(),Opportunity_Auto_Close_Duration__c=90,Opportunity_Auto_Close_Max_Probability__c=70
                                                    ,Extend_Number_of_Days__c=45);
        insert rtSetting;
        
        Opportunity oppty = new Opportunity(Name='test',accountId=acct.Id,CloseDate = date.today(),
                                            recordTypeId=oppRt.getRecordTypeId(),StageName=Label.OppStage_Qualified,
                                            LeadSource='test',OpportunityType__c='Payroll',NSS_Source__c='Inbound',OwnerId=smbRep.Id
                                           ,Auto_Close_Date__c=Date.today().addDays(90));
        insert oppty;
        Task tk = new Task(OwnerId=smbRep.Id, WhatId=oppty.Id,Subject='test',ActivityDate = date.today().addDays(80),Status='Completed');   
        OpptyAutoCloseEvaluation.SKIP_FUTURE_ACT=false;
        test.startTest();
        system.runAs(smbRep){
            insert tk;
        }
        test.stopTest();
        
        Opportunity uOppty = [SELECT Id,Auto_Close_Date__c From Opportunity WHERE Id = :oppty.Id];
        Date checkDate = tk.ActivityDate.addDays((Integer)rtSetting.Extend_Number_of_Days__c);
        system.assertEquals(checkDate,uOppty.Auto_Close_Date__c);
    }//oppWithTaskTest
    
    static testMethod void jointOppWithTaskTest() {
        User[] users = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 2];
        User mmsRep = users[0];
        User asoRep = users[1];
        Account acct = new Account(Name='test account');
        insert acct;
        
        Schema.RecordTypeInfo mmsOppRT = RecordTypeHelper.getRecordType('MMS Opportunity Record Type','Opportunity');
        Schema.RecordTypeInfo pasOppRT = RecordTypeHelper.getRecordType('ASO Opportunity Record Type','Opportunity');        
        RecordType__c mmsRtSetting =  new RecordType__c(Name=mmsOppRT.getName(),ObjectName__c='Opportunity',OpportunityType__c='Payroll',Sales_Org__c='MMS',
                                                        RecordTypeName__c=mmsOppRT.getName(),Opportunity_Auto_Close_Duration__c=90,Opportunity_Auto_Close_Max_Probability__c=70
                                                       ,Extend_Number_of_Days__c=45);
        RecordType__c asoRtSetting =  new RecordType__c(Name=pasOppRT.getName(),ObjectName__c='Opportunity',OpportunityType__c= Label.HR_Pro_Upgrade,Sales_Org__c='PAS',
                                                        RecordTypeName__c=pasOppRT.getName(),Auto_Close_Joint_Only__c=true);
        insert new RecordType__c[]{mmsRtSetting,asoRTSetting};
        Opportunity mmsOppty = new Opportunity(Name='test MMS',accountId=acct.Id,CloseDate = date.today(),
                                            recordTypeId=mmsOppRT.getRecordTypeId(),StageName=Label.OppStage_Qualified,
                                            LeadSource='test',OpportunityType__c='Payroll',NSS_Source__c='Inbound',OwnerId = mmsRep.Id);
        Opportunity asoOppty = new Opportunity(Name='test ASO',accountId=acct.Id,CloseDate = date.today(),
                                            recordTypeId=pasOppRT.getRecordTypeId(),StageName=Label.OppStage_Qualified,
                                            LeadSource='test',OpportunityType__c= Label.HR_Pro_Upgrade,NSS_Source__c='Inbound',OwnerId = asoRep.Id);
        Opportunity[]opptys = new Opportunity[]{mmsOppty,asoOppty};
        insert opptys;
        
        Assert.areEqual(1,[Select count() from Opportunity where AccountId=:acct.Id and Auto_Close_Date__c != null]);
        
        Referral__c mmsReferral = new Referral__c(Selling_Opportunity__c = mmsOppty.Id);
        Referral__c asoReferral = new Referral__c(Selling_Opportunity__c = asoOppty.Id);
        Referral__c[]referrals = new Referral__c[]{mmsReferral,asoReferral}; 
        insert referrals;
            
        ReferralJoin__c refJoin = new ReferralJoin__c(PAS_Referral__c=asoReferral.Id,MMS_Referral__c=mmsReferral.Id);
        insert refJoin;
        
        mmsReferral.ReferralJoin__c = refJoin.Id;
        asoReferral.ReferralJoin__c = refJoin.Id;
        TriggerMethods.clearVariables();
        update referrals;
        
        mmsOppty.ReferralLookup__c = mmsReferral.Id;
        asoOppty.ReferralLookup__c = asoReferral.Id;   
        update opptys;
        
        System.debug('jointOppWithTaskTest before task insert');
        TriggerMethods.clearVariables();
        test.startTest();
        Task tk = new Task(WhatId=asoOppty.Id,Subject='test',ActivityDate = date.today().addDays(70),Status='Completed',OwnerId=asoRep.Id);
        insert tk;

        test.stopTest();
        
        Opportunity uMMSOppty = [SELECT Id,Auto_Close_Date__c From Opportunity WHERE Id = :mmsOppty.Id];
        Date mmsCheckDate = tk.ActivityDate.addDays((Integer)mmsRtSetting.Extend_Number_of_Days__c);
        system.assertEquals(mmsCheckDate,uMMSOppty.Auto_Close_Date__c);
        
        Opportunity uASOOppty = [SELECT Id,Auto_Close_Date__c From Opportunity WHERE Id = :asoOppty.Id];
        system.assertEquals(mmsCheckDate,uASOOppty.Auto_Close_Date__c);
    }//jointOppWithTaskTest
    
    static testMethod void oppWithEventTest() {  
        User you = UserHelper.getRunningUser();
        you.Sales_Org__c = 'PAY';
        update you;
        User smbRep = [SELECT Id,TimeZoneSidKey FROM User WHERE Profile.Name = 'Core Sales - SB' AND isActive = true AND TimeZoneSidKey = 'America/New_York' LIMIT 1];
        system.debug('OpptyAutoCloseEvaluation oppWithEventTest smbRep:'+smbRep.TimeZoneSidKey);
        Account acct = new Account(Name='test account');
        insert acct;
        
        Schema.RecordTypeInfo oppRT = RecordTypeHelper.getRecordType('Core Opportunity Record Type','Opportunity');
        
        RecordType__c rtSetting =  new RecordType__c(Name=oppRT.getName(),ObjectName__c='Opportunity',OpportunityType__c='Payroll',
                                                     Sales_Org__c='PAY',RecordTypeName__c=oppRt.getName(),Opportunity_Auto_Close_Duration__c=10,Opportunity_Auto_Close_Max_Probability__c=70
                                                    ,Extend_Number_of_Days__c=20);
        insert rtSetting;
        
        Opportunity oppty = new Opportunity(Name='test',accountId=acct.Id,CloseDate = date.today(),
                                            recordTypeId=oppRt.getRecordTypeId(),StageName=Label.OppStage_Qualified,
                                            LeadSource='test',OpportunityType__c='Payroll',NSS_Source__c='Inbound',OwnerId=smbRep.Id
                                           ,Auto_Close_Date__c=Date.today().addDays(5));
        insert oppty;
        
        Date startDate = date.today().addDays(2);
        Event ev = new Event(WhatId=oppty.Id,Subject='test',StartDateTime= DateTime.newInstance(startDate.year(),startDate.month(),startDate.day()),DurationInMinutes=60,OwnerId=smbRep.Id,Onsite_or_Virtual__c='Virtual');
        
        System.debug('oppWithEventTest before insert event');
        test.startTest();
        system.runAs(smbRep){
            insert ev;
        }

        test.stopTest();
        
        Opportunity uOppty = [SELECT Id,Auto_Close_Date__c From Opportunity WHERE Id = :oppty.Id];
        Date checkDate = startDate.addDays((Integer)rtSetting.Extend_Number_of_Days__c);
        system.assertEquals(checkDate,uOppty.Auto_Close_Date__c);
    }//oppWithEventTest
    
    static testMethod void jointOppWithEventTest() {
        User[] users = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 2];
        User smbRep = users[0];
        User asoRep = users[1];
        Account acct = new Account(Name='test account');
        insert acct;
        
        Schema.RecordTypeInfo smbOppRT = RecordTypeHelper.getRecordType('MMS Opportunity Record Type','Opportunity');
        Schema.RecordTypeInfo pasOppRT = RecordTypeHelper.getRecordType('ASO Opportunity Record Type','Opportunity');        
        RecordType__c smbRtSetting =  new RecordType__c(Name=smbOppRT.getName(),ObjectName__c='Opportunity',OpportunityType__c='Payroll',
                                                        Sales_Org__c='MMS',RecordTypeName__c=smbOppRT.getName(),Opportunity_Auto_Close_Duration__c=90,Opportunity_Auto_Close_Max_Probability__c=50
                                                       ,Extend_Number_of_Days__c=45);
        RecordType__c asoRtSetting =  new RecordType__c(Name=pasOppRT.getName(),ObjectName__c='Opportunity',OpportunityType__c= Label.HR_Pro_Upgrade,
                                                        Sales_Org__c='PAS',RecordTypeName__c=pasOppRT.getName(),Auto_Close_Joint_Only__c=true);
        insert new RecordType__c[]{smbRtSetting,asoRTSetting};
        Opportunity smbOppty = new Opportunity(Name='test SMB',accountId=acct.Id,CloseDate = date.today(),
                                            recordTypeId=smbOppRT.getRecordTypeId(),StageName=Label.OppStage_Qualified,
                                            LeadSource='test',OpportunityType__c='Payroll',NSS_Source__c='Inbound',OwnerId = smbRep.Id);
        Opportunity asoOppty = new Opportunity(Name='test ASO',accountId=acct.Id,CloseDate = date.today(),
                                            recordTypeId=pasOppRT.getRecordTypeId(),StageName=Label.OppStage_Qualified,
                                            LeadSource='test',OpportunityType__c= Label.HR_Pro_Upgrade,NSS_Source__c='Inbound',OwnerId = asoRep.Id);
        Opportunity[]opptys = new Opportunity[]{smbOppty,asoOppty};
        insert opptys;
        
        Referral__c smbReferral = new Referral__c(Selling_Opportunity__c = smbOppty.Id);
        Referral__c asoReferral = new Referral__c(Selling_Opportunity__c = asoOppty.Id);
        Referral__c[]referrals = new Referral__c[]{smbReferral,asoReferral}; 
        insert referrals;
            
        ReferralJoin__c refJoin = new ReferralJoin__c(PAS_Referral__c=asoReferral.Id,Core_Referral__c=smbReferral.Id);
        insert refJoin;
        
        smbReferral.ReferralJoin__c = refJoin.Id;
        asoReferral.ReferralJoin__c = refJoin.Id;
        TriggerMethods.clearVariables();
        update referrals;
        
        smbOppty.ReferralLookup__c = smbReferral.Id;
        asoOppty.ReferralLookup__c = asoReferral.Id;   
        update opptys;
        
        test.startTest();
        Date startDate = date.today().addDays(70);
        Event ev = new Event(WhatId=smbOppty.Id,Subject='test',StartDateTime= DateTime.newInstance(startDate.year(),startDate.month(),startDate.day()),DurationInMinutes=60,OwnerId=smbRep.Id);
        insert ev;

        test.stopTest();
        
        Opportunity uSMBOppty = [SELECT Id,Auto_Close_Date__c From Opportunity WHERE Id = :smbOppty.Id];
        Date smbCheckDate = startDate.addDays((Integer)smbRtSetting.Extend_Number_of_Days__c);
        system.assertEquals(smbCheckDate,uSMBOppty.Auto_Close_Date__c);
        
        Opportunity uASOOppty = [SELECT Id,Auto_Close_Date__c From Opportunity WHERE Id = :asoOppty.Id];
        system.assertEquals(smbCheckDate,uASOOppty.Auto_Close_Date__c);
    }//jointOppWithEventTest
    
    static testMethod void oppNoLongerEligible() {        
        Account acct = new Account(Name='test account');
        insert acct;
        
        Schema.RecordTypeInfo oppRT = RecordTypeHelper.getRecordType(Label.PAY_Opportunity_Record_Type,'Opportunity');
        Schema.RecordTypeInfo dsaOppRT = RecordTypeHelper.getRecordType(Label.PAY_Opportunity_DSA_Record_Type,'Opportunity');
        
        RecordType__c rtSetting =  new RecordType__c(Name=oppRT.getName(),ObjectName__c='Opportunity',OpportunityType__c='Payroll',
                                                     Sales_Org__c='PAY',RecordTypeName__c=oppRt.getName(),Opportunity_Auto_Close_Duration__c=90,Opportunity_Auto_Close_Max_Probability__c=70);
        insert rtSetting;
        
        Opportunity oppty = new Opportunity(Name='test',accountId=acct.Id,CloseDate = date.today(),
                                            recordTypeId=oppRt.getRecordTypeId(),StageName=Label.OppStage_Qualified,
                                            LeadSource='test',OpportunityType__c='Payroll',NSS_Source__c='Inbound',Auto_Close_Date__c = date.today().addDays(5));
        insert oppty;
        
        test.startTest();
        oppty.RecordTypeId = dsaOppRT.getRecordTypeId();
        oppty.StageName=Label.OppStage_Sold_Submitted;
        update oppty;
        test.stopTest();
        
        Opportunity uOppty = [SELECT Id,Auto_Close_Date__c From Opportunity WHERE Id = :oppty.Id];
        system.assertEquals(null,uOppty.Auto_Close_Date__c);
    } // oppNoLongerEligible
    
    static testMethod void testIntegratedOnly() {        
        User smbRep = [SELECT Id FROM User WHERE Profile.Name = 'Core Sales - SB' AND isActive = true AND TimeZoneSidKey = 'America/New_York' LIMIT 1];
        
        Account acct = new Account(Name='test account');
        insert acct;
        
        Schema.RecordTypeInfo oppRT = RecordTypeHelper.getRecordType('Core Opportunity Record Type','Opportunity');
        
        RecordType__c rtSetting =  new RecordType__c(Name=oppRT.getName(),ObjectName__c='Opportunity',OpportunityType__c='Payroll',
                                                     Sales_Org__c='PAY',RecordTypeName__c=oppRt.getName(),Auto_Close_Joint_Only__c=true);
        insert rtSetting;
        
        test.startTest();
        Opportunity oppty = new Opportunity(Name='test',accountId=acct.Id,CloseDate = date.today(),
                                            recordTypeId=oppRt.getRecordTypeId(),StageName=Label.OppStage_Qualified,
                                            LeadSource='test',OpportunityType__c='Payroll',NSS_Source__c='Inbound');
        system.runAs(smbRep){
            insert oppty;
        }
        test.stopTest();
        
        Opportunity uOppty = [SELECT Id,Auto_Close_Date__c From Opportunity WHERE Id = :oppty.Id];
        system.assertEquals(null,uOppty.Auto_Close_Date__c);
    } // testIntegratedOnly
    
    static testMethod void multipleOppsNoActivity() {
        User[] users = [Select Id, Name from User Where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 4];
        User rep1 = users[0];
        User rep2 = users[1];
        User rep3 = users[2];
        User rep4 = users[3];
        
        Account acct1 = new Account(Name='test account1');
        Account acct2 = new Account(Name='test account2');
        Account acct3 = new Account(Name='test account3');
        Account acct4 = new Account(Name='test account4');
        insert new Account[]{acct1,acct2,acct3,acct4};
            
        String[] excludeLeadSources = new String[]{};
        excludeLeadSources.addAll(OpptyAutoCloseEvaluation.excludeLeadSourceSet);
        String[] excludeOppTypes = new String[]{};
        excludeOppTypes.addAll(OpptyAutoCloseEvaluation.excludeOppTypeSet);
        
        Schema.RecordTypeInfo oppRT = RecordTypeHelper.getRecordType('Core Opportunity Record Type','Opportunity');
        Schema.RecordTypeInfo mmsOppRT = RecordTypeHelper.getRecordType('MMS Opportunity Record Type','Opportunity');
        
        RecordType__c rtSetting1 =  new RecordType__c(Name=oppRT.getName(),ObjectName__c='Opportunity',OpportunityType__c='Payroll',
                                                     Sales_Org__c='PAY',RecordTypeName__c=oppRt.getName(),Opportunity_Auto_Close_Duration__c=90
                                                     ,Opportunity_Auto_Close_Max_Probability__c=70
                                                     ,Non_Inbound_number_of_days__c=50
                                                     ,Extend_Number_of_Days__c=40);
        RecordType__c rtSetting2 =  new RecordType__c(Name=mmsOppRT.getName(),ObjectName__c='Opportunity',OpportunityType__c='Payroll',
                                                     Sales_Org__c='PAY',RecordTypeName__c=mmsOppRT.getName(),Opportunity_Auto_Close_Duration__c=null
                                                     ,Opportunity_Auto_Close_Max_Probability__c=null
                                                     ,Non_Inbound_number_of_days__c=null
                                                     ,Extend_Number_of_Days__c=40);
        insert new RecordType__c[]{rtSetting1,rtSetting2};
        
        Opportunity oppty1 = new Opportunity(Name='test1',accountId=acct1.Id,CloseDate = date.today(), OwnerId=rep1.Id,
                                            recordTypeId=oppRt.getRecordTypeId(),StageName=Label.OppStage_Qualified,
                                            LeadSource='test',OpportunityType__c='Payroll',NSS_Source__c='Inbound');
        Opportunity oppty2 = new Opportunity(Name='test2',accountId=acct2.Id,CloseDate = date.today(), OwnerId=rep2.Id,
                                            recordTypeId=oppRt.getRecordTypeId(),StageName=Label.OppStage_Qualified,
                                            LeadSource='test',OpportunityType__c='Payroll',NSS_Source__c='Outbound');
        Opportunity oppty3 = new Opportunity(Name='test3',accountId=acct3.Id,CloseDate = date.today(), OwnerId=rep3.Id,
                                            recordTypeId=mmsOppRT.getRecordTypeId(),StageName=Label.OppStage_Qualified,
                                            LeadSource='test',OpportunityType__c='Payroll',NSS_Source__c='Inbound');
        // exclude based on lead source
        Opportunity oppty4a = new Opportunity(Name='test4a',accountId=acct4.Id,CloseDate = date.today(), OwnerId=rep4.Id,
                                            recordTypeId=oppRt.getRecordTypeId(),StageName=Label.OppStage_Qualified,
                                            LeadSource=excludeLeadSources[0],OpportunityType__c='Payroll',NSS_Source__c='Inbound');
        // exclude based on opportunity type
        Opportunity oppty4b = new Opportunity(Name='test4b',accountId=acct4.Id,CloseDate = date.today(), OwnerId=rep4.Id,
                                            recordTypeId=oppRt.getRecordTypeId(),StageName=Label.OppStage_Qualified,
                                            LeadSource='test',OpportunityType__c=excludeOppTypes[0],NSS_Source__c='Inbound');
       test.startTest();
        insert new Opportunity[]{oppty1,oppty2,oppty3,oppty4a,oppty4b};
        test.stopTest();
        
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([Select Id, Auto_Close_Date__c
                                                                From Opportunity]);
        // check the inbound opp
        Opportunity checkOpp1 = oppMap.get(oppty1.Id);
        Date checkDate = Date.today().addDays((Integer)rtSetting1.Opportunity_Auto_Close_Duration__c);
        Assert.areEqual(checkDate,checkOpp1.Auto_Close_Date__c);
        
        // check the non-inbound opp
        Opportunity checkOpp2 = oppMap.get(oppty2.Id);
        checkDate = Date.today().addDays((Integer)rtSetting1.Non_Inbound_number_of_days__c);
        Assert.areEqual(checkDate,checkOpp2.Auto_Close_Date__c);

        // check the one that's not setup
        Opportunity checkOpp3 = oppMap.get(oppty3.Id);
        Assert.IsNull(checkOpp3.Auto_Close_Date__c);

        Opportunity checkOpp4a = oppMap.get(oppty4a.Id);
        Assert.IsNull(checkOpp4a.Auto_Close_Date__c);

        Opportunity checkOpp4b = oppMap.get(oppty4b.Id);
        Assert.IsNull(checkOpp4b.Auto_Close_Date__c);
    }//multipleOppsNoActivity
    

} // class OpptyAutoCloseEvaluationTest