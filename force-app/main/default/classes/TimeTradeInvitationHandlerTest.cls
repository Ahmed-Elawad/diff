@istest
public class TimeTradeInvitationHandlerTest {

        public static testmethod void setupData() {
       Opportunity opp1 = new Opportunity(Name='Opp1a',type__c = 'Demo',StageName='Pending',CloseDate=Date.today().addDays(7),OpportunityType__c='TestType1');
       insert opp1;

            TimeTrade_SF1__Invitation__c tsi = new TimeTrade_SF1__Invitation__c();
            tsi.Name = 'test';
            tsi.TimeTrade_SF1__Notes__c = 'Join Webex meeting';
            tsi.TimeTrade_SF1__What_ID__c = opp1.id;
            insert tsi;
        }
}