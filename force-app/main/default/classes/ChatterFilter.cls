/* 
 * Prevents chatter posts and comments based on phrases stored in the ChatterFilter Custom setting
 *
 * History
 * -------
 * 03/17/2014 Justin Stouffer   Created
 *
 */
public with sharing class ChatterFilter {
    
    public static boolean excludeFromFilter {get;set;}
    
    public static void filterPost(list<feedItem> feedItemList){
        list<ChatterFilter__c> chatterFilterList = ChatterFilter__c.getAll().values();
        for(ChatterFilter__c cFilter : chatterFilterList){
            for(feedItem fItem : feedItemList){         
                if(excludeFromFilter != TRUE && fItem.body != NULL && cFilter.Check_Phrase__c != NULL){
                    if(fItem.body.toUpperCase().contains(cFilter.Check_Phrase__c.toUpperCase())){
                        string warnMessage = 'You can\'t use the phrase: ';
                        warnMessage += cFilter.Check_Phrase__c;
                        warnMessage += '. Please revise your message.';
                        fItem.addError((cFilter.Warning_Message__c != NULL ? cFilter.Warning_Message__c : warnMessage));
                    }
                }
            }           
        }
    }
    
    public static void filterComment(list<feedComment> feedCommentList){
        list<ChatterFilter__c> chatterFilterList = ChatterFilter__c.getAll().values();
        for(ChatterFilter__c cFilter : chatterFilterList){
            for(feedComment fComment : feedCommentList){
                if(excludeFromFilter != TRUE && fComment.CommentBody != NULL && cFilter.Check_Phrase__c != NULL){
                    if(fComment.CommentBody.toUpperCase().contains(cFilter.Check_Phrase__c.toUpperCase())){
                        string warnMessage = 'You can\'t use the phrase: ';
                        warnMessage += cFilter.Check_Phrase__c;
                        warnMessage += '. Please revise your message.';
                        fComment.addError((cFilter.Warning_Message__c != NULL ? cFilter.Warning_Message__c : warnMessage));
                    }   
                }
            }           
        }
    }
    
}