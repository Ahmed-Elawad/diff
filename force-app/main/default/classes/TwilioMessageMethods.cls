/** 
* Set the owner of inbound messages to the createdby id of the most recent outbound message to that Phone number.
*
* History
* -------
* 11/30/2018 Justin Stouffer Created
* 07/06/2020  Jacob Hinds         Added without sharing per PMD
*/

public without sharing class TwilioMessageMethods {

    public static void methodForTests() {
        System.debug('This is a test.');
    }
/*    public static void prepareMessage(List<TwilioSF__Message__c> messages) {
        set<string> phoneSet = new set<string>();
        for(TwilioSF__Message__c msg: messages){
            if(msg.TwilioSF__Direction__c == 'inbound'){
                phoneSet.add(msg.TwilioSF__From_Number__c);
            }
        }
        List<TwilioSF__Message__c> messagesOut = [Select createdById, 
                                                    TwilioSF__To_Number__c,
                                                    TwilioSF__From_Number__c
                                                  from TwilioSF__Message__c
                                                  where TwilioSF__Direction__c != 'inbound'
                                                  and TwilioSF__To_Number__c in :phoneSet 
                                                  order by CreatedDate DESC];
        map<string,id> phoneToIdMap = new map<string,id>();
        set<string> alreadyFound = new set<string>();
        if(!messagesOut.isEmpty()){
            for(TwilioSF__Message__c m: messagesOut){
                if(!alreadyFound.contains(m.TwilioSF__To_Number__c)){
                    phoneToIdMap.put(m.TwilioSF__To_Number__c,m.createdById);
                    alreadyFound.add(m.TwilioSF__To_Number__c);
                }
            }
        }
        for(TwilioSF__Message__c msg: messages){
            if(msg.TwilioSF__Direction__c == 'inbound'){
                if(phoneToIdMap.keyset().contains(msg.TwilioSF__From_Number__c)){
                    msg.ownerId = phoneToIdMap.get(msg.TwilioSF__From_Number__c); 
                }
                else{
                    msg.OwnerId = System.Label.TwilioDefaultUser;    
                }
            }       
        }
    }*/
   
}