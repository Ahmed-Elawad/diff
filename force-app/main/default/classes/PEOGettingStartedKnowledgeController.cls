/* Controller for PEOGettingStartedKnowledge Lightning Component
* 	HISTORY
* ___________
*
*	09/29/2021	Jake Hinds	Created
*/
public without sharing class PEOGettingStartedKnowledgeController {
    @AuraEnabled
    public static List<Knowledge__kav> getAllKnowledgeArticles(){
        Knowledge__kav[] knowledgeList = [select id,Title,Article_Body__c,ArticleNumber,Hover_Description__c,UrlName 
                                          from Knowledge__kav where PublishStatus='Online' AND RecordType.Name = 'Community Article' Order By Title ASC];
        
        system.debug('knowledgeList:'+knowledgeList);
        return knowledgeList;
    }
}