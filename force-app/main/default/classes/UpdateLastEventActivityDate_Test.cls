/* Test Methods for UpdateLastEventActivityDate


 * History
 * -------
  12/23/2021 Susmitha/Dan       Created
  04/06/2022 Dan Carmen         Update criteria to always check for closed tasks.

*/
@isTest
public class UpdateLastEventActivityDate_Test {
    
   @testSetup
   public static void setupData() {
      TriggerMethodsTest.createTriggerSetting('EventCheckType', false, true, false, false,new String[]{'UpdateLastEventActivityDate'});
      TriggerMethodsTest.createTriggerSetting('TaskAfter', false, true, false, false,new String[]{'UpdateLastEventActivityDate'});
      TriggerMethodsTest.saveSetupClasses();
   } // setupData
    
	@isTest
    public static void updateLastEventDate_Test(){
    	id refAcctRT = RecordTypeHelper.getRecordType('Core Referral Source Record Type','Referral_Account__c').getRecordTypeId();
    	Referral_Account__c refAcc1 = new Referral_Account__c(name = 'RefAcctCreate'
                                        ,recordtypeid = refAcctRT
                                        ,Referral_Source_Business_Type__c = Label.ReferralSourceFA
                                        ,Street_Address_1__c = '911 Panorama Trail South'
                                        ,City__c = 'Rochester'
                                        ,State_Province__c = 'NY'
                                        ,Zip_Postal_Code__c = '14586');
        insert refAcc1;
        DateTime thisDT = system.now();
        Date todaydate = system.today();
        Event evnt1 = new Event(WhatId=refAcc1.Id, ActivityDate=todaydate, ActivityDateTime=thisDT, DurationInMinutes=60);
        Event evnt2 = new Event(WhatId=refAcc1.Id, ActivityDate=todaydate.addDays(5), ActivityDateTime=thisDT.addDays(5), DurationInMinutes=60);
        insert new Event[]{evnt1,evnt2};
        // check this 
        Referral_Account__c refAcc = [select Id,Last_Activity_Date__c, Last_Event_Date__c from Referral_Account__c where Id=:refAcc1.Id LIMIT 1];
        system.assertEquals(evnt2.ActivityDate,refAcc.Last_Activity_Date__c);
        system.assertEquals(evnt2.ActivityDate,refAcc.Last_Event_Date__c);

        evnt1.ActivityDate=todaydate.addDays(10);
        evnt1.ActivityDateTime=thisDT.addDays(10);
        // reset the trigger
        TriggerMethods.clearVariables();
        update evnt1;
        refAcc = [select Id,Last_Activity_Date__c, Last_Event_Date__c from Referral_Account__c where Id=:refAcc1.Id LIMIT 1];
        system.assertEquals(evnt1.ActivityDate,refAcc.Last_Activity_Date__c);
        system.assertEquals(evnt1.ActivityDate,refAcc.Last_Event_Date__c);

        id refCntctRT = RecordTypeHelper.getRecordType('Core Referral Record Type','Referral_Contact__c').getRecordTypeId();
        List<Referral_Contact__c> refConLst = new List<Referral_Contact__c>();
        Referral_Contact__c refCon1 = new Referral_Contact__c(name = 'First Last'
                                        ,recordtypeid = refCntctRT
                                        ,Referral_Account__c = refAcc1.Id
                                        ,Mailing_Street__c = '123'
                                        ,Mailing_City__c = 'Rochester'
                                        ,Mailing_State__c = 'NY'
                                        ,Mailing_Postal_Code__c = '14514'
                                        ,Mailing_Country__c = 'US');
        refConLst.add(refCon1);
        Referral_Contact__c refCon2 = new Referral_Contact__c(name = 'First Last1'
                                        ,recordtypeid = refCntctRT
                                        ,Referral_Account__c = refAcc1.Id
                                        ,Mailing_Street__c = '1234'
                                        ,Mailing_City__c = 'Rochester'
                                        ,Mailing_State__c = 'NY'
                                        ,Mailing_Postal_Code__c = '14514'
                                        ,Mailing_Country__c = 'US');
        refConLst.add(refCon2);
        insert refConLst;
        
        Event evnt3 = new Event(WhatId=refCon1.Id, ActivityDate=todaydate.addDays(11), ActivityDateTime=thisDT.addDays(11), DurationInMinutes=60);
        Event evnt4 = new Event(WhatId=refCon2.Id, ActivityDate=todaydate.addDays(9), ActivityDateTime=thisDT.addDays(9), DurationInMinutes=60);
        TriggerMethods.clearVariables();
        insert new Event[]{evnt3,evnt4};

        refAcc = [select Id,Last_Activity_Date__c, Last_Event_Date__c from Referral_Account__c where Id=:refAcc1.Id LIMIT 1];
        system.assertEquals(evnt3.ActivityDate,refAcc.Last_Activity_Date__c);
        system.assertEquals(evnt3.ActivityDate,refAcc.Last_Event_Date__c);

        evnt4.ActivityDate=todaydate.addDays(15);
        evnt4.ActivityDateTime=thisDT.addDays(15);
        TriggerMethods.clearVariables();
        update evnt4;
        refAcc = [select Id,Last_Activity_Date__c, Last_Event_Date__c from Referral_Account__c where Id=:refAcc1.Id LIMIT 1];
        system.assertEquals(evnt4.ActivityDate,refAcc.Last_Activity_Date__c);
        system.assertEquals(evnt4.ActivityDate,refAcc.Last_Event_Date__c);
    } // updateLastEventDate_Test
    
    @isTest
    public static void updateLastActivityDate_Test(){
    	id refAcctRT = RecordTypeHelper.getRecordType('Core Referral Source Record Type','Referral_Account__c').getRecordTypeId();
    	Referral_Account__c refAcc1 = new Referral_Account__c(name = 'RefAcctCreate'
                                        ,recordtypeid = refAcctRT
                                        ,Referral_Source_Business_Type__c = Label.ReferralSourceFA
                                        ,Street_Address_1__c = '911 Panorama Trail South'
                                        ,City__c = 'Rochester'
                                        ,State_Province__c = 'NY'
                                        ,Zip_Postal_Code__c = '14586');
        insert refAcc1;

        DateTime thisDT = system.now();
        Date todaydate = system.today();
        Task tsk1 = new Task(WhatId=refAcc1.Id, ActivityDate=todaydate, Status='Completed');
        Task tsk2 = new Task(WhatId=refAcc1.Id, ActivityDate=todaydate.addDays(5), Status='Completed');
        insert new Task[]{tsk1,tsk2};
        Referral_Account__c refAcc = [select Id,Last_Activity_Date__c, Last_Event_Date__c from Referral_Account__c where Id=:refAcc1.Id LIMIT 1];
        system.assertEquals(tsk2.ActivityDate,refAcc.Last_Activity_Date__c);
        system.assertEquals(null,refAcc.Last_Event_Date__c);
        
        tsk1.ActivityDate=todaydate.addDays(10);
        TriggerMethods.clearVariables();
        update tsk1;
        refAcc = [select Id,Last_Activity_Date__c, Last_Event_Date__c from Referral_Account__c where Id=:refAcc1.Id LIMIT 1];
        system.assertEquals(tsk1.ActivityDate,refAcc.Last_Activity_Date__c);
        system.assertEquals(null,refAcc.Last_Event_Date__c);
 
        id refCntctRT = RecordTypeHelper.getRecordType('Core Referral Record Type','Referral_Contact__c').getRecordTypeId();
        List<Referral_Contact__c> refConLst = new List<Referral_Contact__c>();
        Referral_Contact__c refCon1 = new Referral_Contact__c(name = 'First Last'
                                        ,recordtypeid = refCntctRT
                                        ,Referral_Account__c = refAcc1.Id
                                        ,Mailing_Street__c = '123'
                                        ,Mailing_City__c = 'Rochester'
                                        ,Mailing_State__c = 'NY'
                                        ,Mailing_Postal_Code__c = '14514'
                                        ,Mailing_Country__c = 'US');
        refConLst.add(refCon1);
        Referral_Contact__c refCon2 = new Referral_Contact__c(name = 'First Last1'
                                        ,recordtypeid = refCntctRT
                                        ,Referral_Account__c = refAcc1.Id
                                        ,Mailing_Street__c = '1234'
                                        ,Mailing_City__c = 'Rochester'
                                        ,Mailing_State__c = 'NY'
                                        ,Mailing_Postal_Code__c = '14514'
                                        ,Mailing_Country__c = 'US');
        refConLst.add(refCon2);
        insert refConLst;
        
        // these tasks are open so they shouldn't do anything
        Task tsk3 = new Task(WhatId=refCon1.Id, ActivityDate=todaydate.addDays(11),Status='Pending');
        Task tsk4 = new Task(WhatId=refCon2.Id, ActivityDate=todaydate.addDays(9),Status='Pending');
        TriggerMethods.clearVariables();
        insert new Task[]{tsk3,tsk4};
        refAcc = [select Id,Last_Activity_Date__c, Last_Event_Date__c from Referral_Account__c where Id=:refAcc1.Id LIMIT 1];
        // should still be on tsk1's date
        system.assertEquals(tsk1.ActivityDate,refAcc.Last_Activity_Date__c);
        system.assertEquals(null,refAcc.Last_Event_Date__c);
        
        // change the status 
        tsk3.Status='Completed';
        TriggerMethods.clearVariables();
        update tsk3;

        refAcc = [select Id,Last_Activity_Date__c, Last_Event_Date__c from Referral_Account__c where Id=:refAcc1.Id LIMIT 1];
        // should have updated to tsk3
        system.assertEquals(tsk3.ActivityDate,refAcc.Last_Activity_Date__c);
        system.assertEquals(null,refAcc.Last_Event_Date__c);

        tsk4.ActivityDate=todaydate.addDays(15);
        tsk4.Status='Completed';
        TriggerMethods.clearVariables();
        update tsk4;
        refAcc = [select Id,Last_Activity_Date__c, Last_Event_Date__c from Referral_Account__c where Id=:refAcc1.Id LIMIT 1];
        // should have updated to tsk3
        system.assertEquals(tsk4.ActivityDate,refAcc.Last_Activity_Date__c);
        system.assertEquals(null,refAcc.Last_Event_Date__c);
    } // updateLastActivityDate_Test
    
} // UpdateLastEventActivityDate_Test