@isTest
public class EventHelperTest {
    @testSetup
    public static void setupData(){
        TriggerMethodsTest.createTriggerSetting('EventCheckType', false, true, false, false,new String[]{'EventHelper'});
        TriggerMethodsTest.saveSetupClasses();
    } // setupData
    
    static testMethod void testChatterTrigger(){
        //set up architecture for testing 
        User[] testUsers = [Select Id, Name from User where Job_Name__c=:UserHelper.JOB_REP and IsActive=true limit 3];
        User u1 = testUsers[0];
        User u2 = testUsers[1];
        User u3 = testUsers[2];
           
        //create Referral Account 
        Referral_Account__c refAcct = new Referral_Account__c();
        refAcct.Name = 'El Suenito';
        ReferralAccountMethods.SKIP_TRIGGERS=true;
        insert refAcct;

        //create referral contact
        Referral_Contact__c refctct = new Referral_Contact__c();
        refctct.Name = 'Usnavi Vega';
        refctct.Referral_Account__c = refAcct.Id;
        insert refctct;
           
        //create referral - probably not really needed.
        Referral__c ref = new Referral__c();
        ref.Referral_Contact__c = refctct.Id;
        ref.Name = 'Usnavi Vega - El Suenito';
        ref.ActivityDateTime__c = Date.Today();
        ref.User__c = u3.Id;
        ref.Referring_User__c = u1.Id;
        insert ref;

        //create event 
        Event evt = new Event();
        evt.OwnerId = u1.id;
        evt.StartDateTime = Date.Today();
        evt.DurationInMinutes = 15;
        evt.Referral_Contact__c = refCtct.Id;
        insert evt;

        Test.startTest();
        evt.OwnerId = u3.id;
        update evt;
        Test.stopTest();
        
        System.assertEquals(1,EventHelper.nbrChatterPosts);
        //System.assert(evt.OwnerId == u3.Id,'The Event hasn\'t updated the Owner properly');
    } // testChatterTrigger
    
} // class EventHelperTest