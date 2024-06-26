/* 
 * Test methods for the EventCheckData trigger.
 *
 * History
 * -------
 * 01/26/2011 Dan Carmen    Created
 * 12/19/2019 Brandon Vidro Added test for checkEventType
 * 08/27/2020 Added the setupSalesOrgSetting() call to test setDefaultType
 * 11/18/2022 Rohit Ranjan Added method refCtctTest1
 */
@isTest
private class EventCheckDataTest {
    
   @testSetup 
   public static void setupData(){
      UserHelperTest.setupSalesOrgSetting();
   } // setupData


   static testMethod void testInitialPres() {
      User testUsr = [Select id, Sales_Org__c, Name from user where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_MMS limit 1];
      SalesOrg__c socs = SalesOrg__c.getInstance(testUsr.Sales_Org__c);
      System.assertNotEquals(null,socs.IEUP_Type__c);
       
      Opportunity oppty = new Opportunity(Name='Test Oppty', StageName='Pending', CloseDate=Date.today());
      insert oppty;
      DateTime thisDT = DateTime.now();
      Event evnt = new Event(OwnerId=testUsr.Id, ActivityDate=thisDT.date(), ActivityDateTime=thisDT, DurationInMinutes=60);
      insert evnt;
      // test basic event
      evnt = [Select Id, Type, WhatId, Initial_Presentation__c from Event where id=:evnt.id];
      System.assertEquals(false,evnt.Initial_Presentation__c);
      // test type = Presentation - Initial but no opportunity
      evnt.Type = socs.IEUP_Type__c;
      update evnt;
      evnt = [Select Id, Type, WhatId, Initial_Presentation__c from Event where id=:evnt.id];
      System.assertEquals(false,evnt.Initial_Presentation__c);
      // attach the opportunity
      evnt.WhatId = oppty.Id;
      update evnt;
      evnt = [Select Id, Type, WhatId, Initial_Presentation__c from Event where id=:evnt.id];
      System.assertEquals(true,evnt.Initial_Presentation__c);
      // change the type, then should no longer be checked.
      evnt.Type = 'Meeting';
      update evnt;
      evnt = [Select Id, Type, WhatId, Initial_Presentation__c from Event where id=:evnt.id];
      System.assertEquals(false,evnt.Initial_Presentation__c);
      
      // test referral contact is populated
      CreateTestData.createReferralAandC();
	  Referral_Contact__c rc = [Select Id, Name from Referral_Contact__c where Name = 'First Ref Ctct1'];
	  Event evnt2 = new Event(OwnerId=testUsr.Id, ActivityDate=thisDT.date(), ActivityDateTime=thisDT, DurationInMinutes=60, WhatId=rc.Id);
      insert evnt2;
      Event evnt2Updated = [Select Id, WhatId, Referral_Contact__c from Event where id=:evnt2.Id]; 
      System.assertEquals(rc.Id, evnt2Updated.Referral_Contact__c);
      
   } // testInitialPres
    
   static testMethod void testcheckEventTypeInsert() {
      User testUsr = [Select id, Sales_Org__c, Name from user where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_MMS limit 1];
      SalesOrg__c socs = SalesOrg__c.getInstance(testUsr.Sales_Org__c);
      System.assertNotEquals(null,socs.IEUP_Type__c);
        Test.startTest();
        Opportunity oppty = new Opportunity(Name='Test Oppty', StageName='Pending', CloseDate=Date.today(),Type__c = 'Demo');
        insert oppty;
        TimeTrade_SF1__Invitation__c tsi = new TimeTrade_SF1__Invitation__c();
            tsi.Name = 'test';
            tsi.TimeTrade_SF1__Notes__c = 'Join Webex meeting';
            tsi.TimeTrade_SF1__What_ID__c = oppty.id;
            insert tsi;
        DateTime thisDT = DateTime.now();
        Event evnt = new Event(OwnerId=testUsr.Id, ActivityDate=thisDT.date(), ActivityDateTime=thisDT, DurationInMinutes=60, Type=socs.IEUP_Type__c, WhatId = oppty.Id, Meeting_Not_Held__c = false,TimeTrade_SF1__Invitation__c=tsi.Id);
        
        insert evnt;
        evnt = [Select Id, Type, WhatId, Meeting_Not_Held__c from Event where id=:evnt.id];
        oppty = [Select Id, Number_of_Events__c from Opportunity where id=:oppty.Id];
        System.assertEquals(evnt.Type, 'Presentation - Initial');
        System.assertEquals(evnt.WhatId, oppty.Id);
        System.assertEquals(evnt.Meeting_Not_Held__c, false);
        System.assertEquals(oppty.Number_of_Events__c, 1);
        Event evntTwo = new Event(OwnerId=testUsr.Id, ActivityDate=thisDT.date(), ActivityDateTime=thisDT, DurationInMinutes=60, Type=socs.IEUP_Type__c, WhatId = oppty.Id, Meeting_Not_Held__c = false);
        try{
        	insert evntTwo;
            System.assertEquals(1,2,'Should not get here');
        }
        catch(Exception e) {
            Boolean expectedExceptionThrown = e.getMessage().contains('An initial Presentation already exists on this Opportunity. Please select a different meeting type or create a new Opportunity to log a new Initial Presentation');
            system.assertEquals(expectedExceptionThrown, true);
        }
        Test.stopTest();
        System.assertEquals(oppty.Number_of_Events__c, 1);
    }
    
    static testMethod void refCtctTest1() {
        Test.startTest();
        User testUsr = [Select id, Sales_Org__c, Name from user where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_MMS limit 1];
          SalesOrg__c socs = SalesOrg__c.getInstance(testUsr.Sales_Org__c);
          ReferralObjectsSync.SKIP_SYNC = true;
        
        Schema.RecordTypeInfo hrsRefAcctRt = RecordTypeHelper.getRecordType('HRS Referral Source Record Type', 'Referral_Account__c');
        Schema.RecordTypeInfo hrsRefCtctRt = RecordTypeHelper.getRecordType('HRS Referral Record Type', 'Referral_Contact__c');
        
        Referral_Account__c refacct = new Referral_Account__c (name = 'Referral Account1'
                                ,RecordTypeId=hrsRefAcctRt.getRecordTypeId()
                                ,Referral_Type__c = 'Broker'
                                ,Zip_Postal_Code__c = '10000'
                                ,To_Be_Deleted__c = false);
        insert refacct;
                
        Referral_Contact__c refcon1 = new Referral_Contact__c(Name = 'First Ref Ctct1'
                                ,RecordTypeId=hrsRefCtctRt.getRecordTypeId()
                                ,Phone__c = '585-555-1212'
                                ,Email__c = 'fLast1@abc.com'
                                ,Referral_Type__c = '100 Broker'
                                ,Referral_Account__c = refacct.Id,Type__c = 'Demo');
        insert refcon1;
        TimeTrade_SF1__Invitation__c tsi = new TimeTrade_SF1__Invitation__c();
            tsi.Name = 'test';
            tsi.TimeTrade_SF1__Notes__c = 'Join Webex meeting';
            tsi.TimeTrade_SF1__What_ID__c = refcon1.id;
            insert tsi;
        DateTime thisDT = DateTime.now();
        Event evnt = new Event(OwnerId=testUsr.Id, ActivityDate=thisDT.date(), ActivityDateTime=thisDT, DurationInMinutes=60, Type=socs.IEUP_Type__c, WhatId = refcon1.Id, Meeting_Not_Held__c = false,TimeTrade_SF1__Invitation__c=tsi.Id);
        insert evnt;
    
        evnt = [Select Id, Type, WhatId, Meeting_Not_Held__c from Event where id=:evnt.id];
        refcon1 = [Select Id from Referral_Contact__c where id=:refcon1.Id];
        System.assertEquals(evnt.Type, 'Presentation - Initial');
        System.assertEquals(evnt.WhatId, refcon1.Id);
        System.assertEquals(evnt.Meeting_Not_Held__c, false);
        Test.stopTest();
    
    } 
} // class EventCheckDataTest