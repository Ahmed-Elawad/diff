/* 
 * Test methods for the ReferralScoreController
 *
 * History
 * -------
   05/17/2016 Dan Carmen   Created
 *
 */
@isTest
private class ReferralScoreControllerTest {

   static testMethod void testController() {
      // set so we know the values for the test
      ReferralScoreController.REFERRAL_SOURCES = new String[]{'CPA','FA','Banker'};
      ReferralScoreController rsc = new ReferralScoreController();
      System.assertEquals(false,rsc.hasSetups);
      System.assertEquals(true,ApexPages.hasMessages());
      ApexPages.Message msg = ApexPages.getMessages().get(0);
      System.assertEquals(true,msg.getDetail().contains('No records are setup!'));

      // add two records
      rsc.addNewRecord();
      rsc.addNewRecord();
      System.assertEquals(true,rsc.hasSetups);
      System.assertEquals(2,rsc.setups.size());
      
      rsc.setups[0].RangeMin__c=0;
      rsc.setups[0].RangeMax__c=1;
      rsc.setups[0].ReferralSource__c='CPA';
      rsc.setups[0].ReferralType__c='Level 1';

      rsc.setups[1].RangeMin__c=0;
      rsc.setups[1].RangeMax__c=2;
      rsc.setups[1].ReferralSource__c='CPA';
      rsc.setups[1].ReferralType__c='Level 2';
      
      // this should fail - same minimum range
      rsc.saveRecords();
      System.assertEquals(2,ApexPages.getMessages().size());
      msg = ApexPages.getMessages().get(1);
      System.assertEquals(true,msg.getDetail().contains('There is more than one'));
      
      rsc.setups[1].RangeMin__c=1;
      rsc.saveRecords();
      // another error message should be created
      System.assertEquals(3,ApexPages.getMessages().size());
      msg = ApexPages.getMessages().get(2);
      System.assertEquals(true,msg.getDetail().contains('The ranges for the Referral Score setup cannot overlap'));
      
      rsc.setups[1].RangeMin__c=2;
      rsc.setups[1].RangeMax__c=3;
      rsc.saveRecords();

      // make sure they saved.
      System.assertEquals(2,[Select count() from ReferralScoreSetup__c]);
      
      rsc.addNewRecord();
      System.assertEquals(3,rsc.setups.size());

      rsc.cancelAdd();
      System.assertEquals(2,rsc.setups.size());
      
      rsc.addNewRecord();
      System.assertEquals(3,rsc.setups.size());

      // test adding one for a different source
      rsc.setups[2].RangeMin__c=0;
      rsc.setups[2].RangeMax__c=1;
      rsc.setups[2].ReferralSource__c='FA';
      rsc.setups[2].ReferralType__c='Level 1';

      rsc.saveRecords();
      System.assertEquals(3,[Select count() from ReferralScoreSetup__c]);

   } // testController
   
} // class ReferralScoreControllerTest