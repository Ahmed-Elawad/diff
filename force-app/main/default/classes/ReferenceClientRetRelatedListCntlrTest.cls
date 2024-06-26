/* 

  History
  -------
  10/12/2023 Carrie Marciano	created, added code to create banner on Reference Client Retention object

*/

@isTest
public class ReferenceClientRetRelatedListCntlrTest {
	@testSetup
   	public static void setupData() {
  	    ObjectBannerAuraServiceTest.setupData();
  	 } // setupData
    
    @isTest static void getReferenceClientRetentionForRCRAcctIdTest() {
        test.startTest();
		
        Account Acct = ObjectBannerAuraServiceTest.getTestAcctbyName('ACCT1');
       	Reference_Client_Retention__c rcr = [Select Id from Reference_Client_Retention__c where Reference_Client_Retention__c.Prospect_Client_Name__c =:Acct.Id LIMIT 1]; 

        ReferenceClientRetRelatedListController.DataEnvelope envelope = ReferenceClientRetRelatedListController.getReferenceClientRetentionForRCRAcctId(rcr.Id);
        List<Reference_Client_Retention__c> refClientRets= envelope.refClientRets;
        test.stopTest();
        
        System.assertEquals(refClientRets.size() == 2, true);
	}
	
}