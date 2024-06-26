trigger TimeTradeInvitation on TimeTrade_SF1__Invitation__c (before insert) {

if(trigger.isinsert && trigger.isbefore)
{ 
    list<TimeTrade_SF1__Invitation__c> tts = new list<TimeTrade_SF1__Invitation__c>();
    tts =  (list<TimeTrade_SF1__Invitation__c>)trigger.new;
   TimeTradeInvitationHandler.LinkTTtoOpportunity(tts);
}

}