/* 
 * If the event has a certain type, update a related field on another object.
 *
 * History
 * -------
 * 03/23/2010 Dan Carmen   Created
   08/25/2011 Dan Carmen   Added Explore Paychex 2
   02/26/2018 Cindy Freeman  Added test for updateOptyCount
   06/04/2018 Jacob Hinds   changing updateOptyCount to testUpdateOptyCountStatus
   01/10/2020 Brandon Vidro Added test for IEUP_Date__c logic
   04/17/2021 Dan Carmen    Changed call to queryActivityEmailMap
   05/18/2021 	Carrie Marciano updated StageNames with OppStage labels
   03/06/2024 Dan Carmen      Update updateOppEvtCreateDelete to only select open opps

*/
@isTest
private class EventCheckTypeTest {

   static testMethod void testProcessExplorePayx() {
      
      // create a referral contact
      Referral_Contact__c rc1 = new Referral_Contact__c(name='Contact 1');
      Referral_Contact__c[] rcs = new Referral_Contact__c[]{rc1};
      insert rcs;
      rc1 = [Select Id, Name, Explore_Date__c, Explore_2_Date__c from Referral_Contact__c where Id = :rc1.Id];
      // confirm there is not a date set
      System.assertEquals(null,rc1.Explore_Date__c);
      System.assertEquals(null,rc1.Explore_2_Date__c);

      // create an event
      Event evnt1 = new Event(Type='Explore Paychex',WhatId=rc1.Id
                            ,Subject='Other'
                            ,ActivityDate=Date.today()
                            ,ActivityDateTime=DateTime.now()
                            ,DurationInMinutes=60);
      Event evnt2 = new Event(Type='Explore Paychex 2',WhatId=rc1.Id
                            ,Subject='Other'
                            ,ActivityDate=Date.today()
                            ,ActivityDateTime=DateTime.now()
                            ,DurationInMinutes=60);
      Event[] evnts = new Event[]{evnt1,evnt2}; 
      insert evnts;
      
      // verify Paychex Explore Date updates on referral contact
      rc1 = [Select Id, Name, Explore_Date__c, Explore_2_Date__c from Referral_Contact__c where Id = :rc1.Id];
      System.assertEquals(evnt1.ActivityDate,rc1.Explore_Date__c);
      System.assertEquals(evnt2.ActivityDate,rc1.Explore_2_Date__c);
      
      // update the event
      evnt1.ActivityDate = Date.today().addDays(1);
      evnt1.ActivityDateTime = DateTime.now().addDays(1);
      update evnt1;

      // verify Paychex Explore Date updates on referral contact
      rc1 = [Select Id, Name, Explore_Date__c, Explore_2_Date__c from Referral_Contact__c where Id = :rc1.Id];
      System.assertEquals(evnt1.ActivityDate,rc1.Explore_Date__c);
      
      // create a new event, update the type to Explore Paychex.
      rc1.Explore_Date__c = null;
      update rc1;
       
      
      TimeTrade_SF1__Invitation__c tsi = new TimeTrade_SF1__Invitation__c();
            tsi.Name = 'test';
            tsi.TimeTrade_SF1__Notes__c = 'Join Webex meeting';
            tsi.TimeTrade_SF1__What_ID__c = rc1.id;
            insert tsi; 
      
      evnt1 = new Event(Type='Other',WhatId=rc1.Id
                            ,Subject='Other'
                            ,ActivityDate=Date.today()
                            ,ActivityDateTime=DateTime.now()
                            ,Appointment_Type__c = 'Demo'
                            ,TimeTrade_SF1__Invitation__c = tsi.id
                            ,DurationInMinutes=60);
      insert evnt1;
      
            // verify Paychex Explore Date updates on referral contact
      rc1 = [Select Id, Name, Explore_Date__c from Referral_Contact__c where Id = :rc1.Id];
      System.assertEquals(null,rc1.Explore_Date__c);
      
      evnt1.Type = 'Explore Paychex';
      update evnt1;
      
      // verify Paychex Explore Date updates on referral contact
      rc1 = [Select Id, Name, Explore_Date__c from Referral_Contact__c where Id = :rc1.Id];
      System.assertEquals(evnt1.ActivityDate,rc1.Explore_Date__c);

      // test for exception - cause a validation error
      rc1.Downloaded_Paychex_Icon__c = 'Attempted-Completed';
      update rc1;
      
      // update the event
      evnt1.ActivityDate = Date.today().addDays(1);
      evnt1.ActivityDateTime = DateTime.now().addDays(1);
      try {
         update evnt1;
      } catch (DmlException e) {
         System.assertEquals(true,e.getMessage().contains('Error while attempting to update the Referral Contact'));
      }
      
   } // testProcessExplorePayx
   
   static testMethod void testUpdateOptyCountStatus() {
        Schema.RecordTypeInfo acctRT = RecordTypeHelper.getRecordType(Label.RT_Core_Account, ObjectHelper.OBJECT_ACCOUNT);
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctRT.getRecordTypeId()
                                ,ownerId = UserInfo.getUserId()
                                ,Phone = '555-1212');
        insert acct1;       
        
        Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,ObjectHelper.OBJECT_OPPTY);
        Opportunity oppty1 = new Opportunity(Name='Test Core Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId()
                                         ,AccountId=acct1.Id
                                         ,StageName=Label.OppStage_Gained_Access
                                         ,IEUP_Date__c=null    
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=UserInfo.getUserId());
        Opportunity oppty2 = new Opportunity(Name='Test Core Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId()
                                         ,AccountId=acct1.Id
                                         ,StageName=Label.OppStage_Gained_Access
                                         ,IEUP_Date__c=null    
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=UserInfo.getUserId());
        Opportunity[] opptys = new Opportunity[]{oppty1,oppty2};                                 
        insert opptys;
        
       User u = [select id from user where profile.name = 'Sales Engineer' AND isActive = true limit 1];
               String[] teamRoles = Label.OppyTeamMemberToKeepWhenOwnerChanged.split(',');
      OpportunityTeamMember otm1 = new OpportunityTeamMember(OpportunityId=oppty1.Id, UserId=u.Id, TeamMemberRole=teamRoles[0]);
       insert otm1;

       Schema.RecordTypeInfo evRT = RecordTypeHelper.getRecordType('Core Event Record Type', 'Event');
        insert new SalesOrg__c(Name='PAY',EventRecordTypeName__c=evRT.Name,OpptyRecordTypeName__c=OpportunityCreateCase.RT_OPPTY_CORE,
                                OppFirstStage__c = Label.OppStage_Gained_Access,OppEUPStage__c='Plan');
        
            TimeTrade_SF1__Invitation__c tsi = new TimeTrade_SF1__Invitation__c();
            tsi.Name = 'test';
            tsi.TimeTrade_SF1__Notes__c = 'Join Webex meeting';
            tsi.TimeTrade_SF1__What_ID__c = oppty1.id;
            insert tsi;

       Test.startTest();
        // create an event
        Event evnt1 = new Event(Type='Presentation - Initial',WhatId=oppty1.Id
                            ,Subject='Opty1 Event'
                            ,ActivityDate=Date.today()
                            ,ActivityDateTime=DateTime.now()
                            ,RecordTypeId = evRT.getRecordTypeId()
                            ,Appointment_Type__c = 'Demo'
                            ,OwnerId=u.id
                            ,TimeTrade_SF1__Invitation__c = tsi.id
       						,DurationInMinutes=60);
        Event evnt2 = new Event(WhatId=oppty2.Id
                            ,Subject='Opty2 Event'
                            ,ActivityDate=Date.today()
                            ,ActivityDateTime=DateTime.now()
                            ,RecordTypeId = evRT.getRecordTypeId()
                            ,DurationInMinutes=60);                            
        Event[] evnts = new Event[]{evnt1,evnt2}; 
        insert evnts;
        
        Opportunity opty1 = [Select Id, Number_of_Events__c,StageName, IEUP_Date__c from Opportunity where id = :oppty1.Id];
        System.assertEquals(1, opty1.Number_Of_Events__c);
        System.assertEquals('Plan',opty1.StageName);
        System.assertEquals(evnt1.ActivityDate, opty1.IEUP_Date__c);
       
        
        List<String> validOutcomeSet = new List<String>(Label.Event_Outcome_Complete.split(';'));
        evnt1.Outcome__c = validOutcomeSet[0];

        update evnt1;
        opty1 = [Select Id, Number_of_Events__c,StageName from Opportunity where id = :oppty1.Id];
        System.assertEquals(Label.OppStage_Discovery,opty1.StageName);
        
        delete evnt1;
        opty1 = [Select Id, Number_of_Events__c,StageName from Opportunity where id = :oppty1.Id];
        System.assertEquals(0, opty1.Number_Of_Events__c);
        System.assertEquals(Label.OppStage_Gained_Access,opty1.StageName);
        
        Event evnt2a = new Event(Type='Opty2a Event',WhatId=oppty2.Id
                            ,Subject='Other'
                            ,ActivityDate=Date.today()
                            ,DurationInMinutes=60
                            ,isRecurrence=true
                            ,RecurrenceStartDateTime=System.Now()
                            ,RecurrenceEndDateOnly=System.today().addDays(3)
                            ,RecurrenceType='RecursDaily'
                            ,RecurrenceInterval=1);
        insert evnt2a;                            
        
        Opportunity opty2 = [Select Id, Number_of_Events__c, IEUP_Date__c from Opportunity where id = :oppty2.Id];
        System.assertEquals(5, opty2.Number_Of_Events__c);
        System.assertEquals(null, opty2.IEUP_Date__c);
        Test.stopTest();
   
   } // testupdateOptyCountStatus
    
    static testMethod void testCreateOrphanDrift() {
        DateTime thisDT = DateTime.now();
        Event evt1 = new Event(Subject='Meeting Booked with Drift', Type='Drift Follow Up Call', ActivityDate=thisDT.date(), ActivityDateTime=thisDT, DurationInMinutes=60);
        Test.startTest();
        insert evt1;
        Test.stopTest();
        Integer nbrOrphanRecs = [select count() from TaskOrphanCall__c where EventId__c =:evt1.Id];
        System.assertEquals(1, nbrOrphanRecs);   
        TaskOrphanCall__c toc = [Select Id, Name, EventId__c from TaskOrphanCall__c where EventId__c = :evt1.Id];
        Event evt = [Select Id from Event where Id = :evt1.Id];
        System.assertEquals(toc.EventId__c, evt.Id);
    } // testCreateOrphanDrift
    
} // class EventCheckTypeTest