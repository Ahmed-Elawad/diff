public class TimeTradeInvitationHandler {

    public static void LinkTTtoOpportunity(list<TimeTrade_SF1__Invitation__c> TTInvitations)
    {
        set<id> opportunityids = new set<id>();
        for(TimeTrade_SF1__Invitation__c TSI: TTInvitations)
        {
            if(TSI.TimeTrade_SF1__What_ID__c != null && TSI.TimeTrade_SF1__What_ID__c.startsWith('006'))
            {
              if(tsi.TimeTrade_SF1__Location_Information__c == 'Physical' && tsi.TimeTrade_SF1__Location__c.contains('See WebEx Information Enclosed') && (tsi.TimeTrade_SF1__Notes__c == null || (!tsi.TimeTrade_SF1__Notes__c.contains('paychex.webex.com') && !tsi.TimeTrade_SF1__Notes__c.contains('Join WebEx meeting'))))
             {
               tsi.addError('Please insert webex meeting details in the message section'); 
             } 
                opportunityids.add(TSI.TimeTrade_SF1__What_ID__c);
            }
        }
        
        map<id,opportunity> oppMap = new map<id,opportunity>([select id,name from opportunity where id in : opportunityids]);
        for(TimeTrade_SF1__Invitation__c TSI: TTInvitations)
        {
            if(TSI.TimeTrade_SF1__What_ID__c != null && TSI.TimeTrade_SF1__What_ID__c.startsWith('006'))
            {
                
                tsi.Related_Opportunity__c ='<a href=' +System.URL.getSalesforceBaseUrl().toExternalForm()+'/'+TSI.TimeTrade_SF1__What_ID__c+' >'+ oppMap.get(TSI.TimeTrade_SF1__What_ID__c).name+'</a> <br/>';
                System.debug('Related_Opportunity__c = '+tsi.Related_Opportunity__c);
            }
        }
    }
}