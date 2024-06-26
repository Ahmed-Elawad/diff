/* Controller for PEOGettingStartedKnowledge Lightning Component
* 	HISTORY
* ___________
*
*	09/29/2021	Jake Hinds	Created
*/
@isTest
public class PEOGettingStartedKnowledgeControllerTest {
	static testMethod void getAllKnowledgeTest() {
        Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType('Community Article', 'Knowledge__kav');
        Knowledge__kav article = new Knowledge__kav(Title='test',RecordTypeId=rt.getRecordTypeId(),URLName='test');
        insert article;
        knowledge__kav uArticle = [SELECT Id,Title,KnowledgeArticleId FROM knowledge__kav WHERE id =: article.Id LIMIT 1];
        KbManagement.PublishingService.publishArticle(uArticle.KnowledgeArticleId, true);
        Knowledge__kav[] articleList = PEOGettingStartedKnowledgeController.getAllKnowledgeArticles();
        system.assertEquals(1,articleList.size());
    }
}