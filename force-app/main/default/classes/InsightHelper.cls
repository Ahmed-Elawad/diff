/* 
 * 10/09/2020 Pujitha Madmananchi       Created.
   07/26/2021 Pujitha Madmananchi       ChatterPost on Lead/Contact
 * 
 * 
 */

public without sharing class InsightHelper{
    public static void updateAccount(List<Marketing_Insights__c> newRecords){
        Set<Id> ctctId = new Set<Id>();
        Map<Id, Id> ctctAccMap = new Map<Id, Id>();
        
        for (Marketing_Insights__c ins : newRecords){
            if(ins.Contact__c!= null){
                ctctId.add(ins.Contact__c);
            }
        } 
        System.debug(ctctId);
               
        for(Contact con : [SELECT Id, AccountId
                           FROM Contact
                           WHERE Id =:ctctId]){
            ctctAccMap.put(con.Id,con.AccountId);
        }
        
        if(!ctctAccMap.isEmpty()){
            for(Marketing_Insights__c ins : newRecords){
                if(ctctAccMap.containsKey(ins.Contact__c)){
                    ins.Account__c = ctctAccMap.get(ins.Contact__c);
                }            
            }
        }        
    }

    public static void ChatterPost(List<Marketing_Insights__c> newRecords){

        List<ID> usersToMention = new List<ID>();
        List<ID> leadIds = new List<ID>();
        List<ID> contactIds = new List<ID>();
        
        for (Marketing_Insights__c ins : newRecords){
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