/** 
 * The test methods for the RefPEOUpdateOppty class and trigger.
 *
 * History
 * -------
 * 10/11/2011 Dan Carmen   Created
 * 01/04/2018 Cindy Freeman Modified for Pass to New Loads only changing status if not Sold
 * 05/08/2018 Frank Lurz   Modified Opportunity asserts for pending deactivation of the RefPEOUpdateOppty class per Fast Track Case 28594622
 *
 */
@isTest
private class RefPEOUpdateOpptyTest {

   static testMethod void testUpdate() {
      // create Opportunity
      Opportunity opp1 = new Opportunity(Name='Opp1 test',CloseDate=Date.today(), StageName='Qualified');
      insert opp1;
      
      Case c = new Case();
      insert c;
      
      // create reference object
      Reference_PEO__c ref1 = new Reference_PEO__c(Opportunity__c=opp1.Id, Parent_Case__c = c.Id, Current_Step__c = 'Step');
      insert ref1;
      
      // update pass to new loads flag
      ref1.Pass_to_New_Loads__c = true;
      update ref1;
      
      // verify opportunity is updated
      opp1 = [Select Id, Name, StageName from Opportunity where Id=:opp1.Id];
      /***  FL commented/modified this code on 5/8/18 per Fast Track Case 28594622  ***/
      /***System.assertEquals('Sold - Submitted',opp1.StageName);***/
      System.assertEquals('Qualified',opp1.StageName);

      // update client processed date
      ref1.Client_Processed__c = Date.today();
      update ref1;
      
      // verify opportunity is updated
      opp1 = [Select Id, Name, StageName from Opportunity where Id=:opp1.Id];
      /***  FL commented/modified this code on 5/8/18 per Fast Track Case 28594622  ***/
      /***System.assertEquals('Sold - Started',opp1.StageName);***/
      System.assertEquals('Qualified',opp1.StageName);

   } // testUpdate
   
} // class RefPEOUpdateOpptyTest