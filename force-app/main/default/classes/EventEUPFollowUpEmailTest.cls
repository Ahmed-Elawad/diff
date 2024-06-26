/* 
 * Sends marketing email after EUP.  Called from EventCheckData.trigger, workflow Automated HCM Followup Email
 *
 * History
 * -------
 * 12/06/2017 Jake Hinds  Created
 * 02/09/2018 Jake Hinds  Adding opp type
 */
@isTest
private class EventEUPFollowUpEmailTest {

    static testMethod void testEmail() {
      User salesRep = [SELECT ID FROM User WHERE Profile.Name = 'Core Sales - SB' and IsActive = true LIMIT 1];
      User nsr = [SELECT ID From User WHERE Profile.Name = 'NSS Inbound Rep' and IsActive = true LIMIT 1];
      Id coreOppRT = RecordTypeHelper.getRecordType('Core Opportunity Record Type','Opportunity').getRecordTypeId();
      Id coreEvRT = RecordTypeHelper.getRecordType(Label.RT_Core_Event,'Event').getRecordTypeId();
      Account acct = new Account(Name='Acct',OwnerId=salesRep.Id);
        insert acct;
        Contact ctct = new Contact(OwnerId=salesRep.Id,FirstName='Test',LastName='Guy',Email='testguy@test.guy',Phone='1234567890',AccountId=acct.Id);
      insert ctct;
      Opportunity opp = new Opportunity(OwnerId=salesRep.Id,Name='testOpp',Type='Payroll',StageName='Pending - Cold',CloseDate=date.today(),RecordTypeId=coreOppRT);
      insert opp;
      Test.startTest();
      system.runAs(nsr){
        Event ev = new Event(OwnerId=salesRep.Id,WhatId=opp.Id,WhoId=ctct.Id,Type='Presentation - Initial',Subject='Test',RecordTypeId=coreEvRT,DurationInMinutes=10,ActivityDateTime=system.now());
      insert ev;
      Event[] events = new Event[]{ev};
          EventEUPFollowUpEmail.sendEUPFollowUp(events);
          system.assertEquals(true,EventEUPFollowUpEmail.emailSent);
          
          ctct.HasOptedOutOfEmail=true;
          update ctct;
          
          EventEUPFollowUpEmail.emailsAlreadySent.clear();
          EventEUPFollowUpEmail.sendEUPFollowUp(events);
          system.assertEquals(false,EventEUPFollowUpEmail.emailSent);
          
          Test.stopTest();
      } 
      
    }
}