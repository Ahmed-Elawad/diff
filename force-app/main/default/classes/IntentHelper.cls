/* 
 * 12/13/2023 Shilpa Govindarajulu       APR0155814-Created
 * 
 * 
 */

public without sharing class IntentHelper {
    public static void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap){
        if(Trigger.isAfter){
        	chatterPost(recs);
        }
    }
	public static void chatterPost(List<Customer_Intent_Signal__c> newRecords){

        List<ID> usersToMention = new List<ID>();
        List<ID> leadIds = new List<ID>();
        List<ID> contactIds = new List<ID>();
        
        for (Customer_Intent_Signal__c ins : newRecords){
            if(ins.Assessment_Link__c!= null){
                if(ins.Lead__c!= null){
                    leadIds.add(ins.Lead__c);
                }
                if(ins.Contact__c!= null) {
                    contactIds.add(ins.Contact__c);
                }
            }
        }

        if(!leadIds.isEmpty()){
            List<Lead> leadList = [SELECT Id, OwnerId, Company, 
                                       Street, City, State, PostalCode, 
                                       FirstName, LastName, Phone, Email, 
                                       Bank_Product_Of_Interest__c, NumberOfEmployees, Frequency__c,
                                        Current_Prior_Method__c 
                                    FROM Lead WHERE Id IN :leadIds];
            
            for(Lead l : leadList) {
               usersToMention.add(l.OwnerId);
               String postText = 'A new MMS Assessment has been completed and is available in Salesforce for review. \n';
               postText += ChatterMentionPost.buildChatterMessage(l);
               System.debug('lead postText'+postText);
               chatterMentionPost.createChatterMentionPost(l.id, usersToMention, postText);
            } 
        }
   
         if(!contactIds.isEmpty()){
            List<Contact> ctctList = [SELECT Id, OwnerId, MailingStreet,
                                            MailingCity, MailingState, 
                                            MailingPostalCode, name, Phone, Email 
                                        FROM Contact WHERE Id IN :contactIds];
            for(Contact ctct : ctctList) {
               usersToMention.add(ctct.OwnerId);
               String postText = 'A new MMS Assessment has been completed and is available in Salesforce for review. \n';
               postText += ChatterMentionPost.buildChatterMessage(ctct);
               System.debug('contact postText '+postText);
               chatterMentionPost.createChatterMentionPost(ctct.id, usersToMention, postText);
            } 
         }

         ChatterMentionPost.checkPostFeedElements();

    }
}