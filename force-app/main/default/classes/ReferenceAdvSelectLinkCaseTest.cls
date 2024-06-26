/* 
 * Test methods for the ReferenceAdvSelectCreateCase class and trigger.
 *
 * History
 * -------
 * 01/31/2012 Cindy Freeman     Created
 * 11/10/2017 Lynn Michels      Split test class to fix "too many SOQL queries" error
 * 05/11/2018 Frank Lurz        Modified test class per commenting out update of Opportunity Stage per Case 28594622
 *
 */

@isTest
private class ReferenceAdvSelectLinkCaseTest {
    
    static testmethod void createTestAccounts() {
    
      // create an account
      Account acct = new Account(Name='Test Acct');
      insert acct;
      // create a contact
      //Contact ctct = new Contact(FirstName='Test', LastName='Contact', AccountId=acct.Id);
      //insert ctct;

      // create a 401k opportunity
      Schema.RecordTypeInfo opptyRt = RecordTypeHelper.getRecordType('HRS 401(k) Opportunity Record Type','Opportunity');
      Opportunity oppty1 = new Opportunity(Name='Test Opporty', RecordTypeId=opptyRt.getRecordTypeId(),AccountId=acct.Id
                                         ,StageName='Pending'
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=UserInfo.getUserId());
      insert oppty1;
        
      // mark opportunity as sold so case is created    
      oppty1.StageName = 'Sold';
      oppty1.Service_Location__c = OpportunityCreateCase.ADV_SERVICE_CENTER;
      update oppty1;
      System.assertEquals(1,[Select count() from Case where Opportunity__c=:oppty1.Id]);

      Case c = [SELECT Id, CaseNumber from Case where Opportunity__c = :oppty1.Id];
      
      // test for reference object to be linked to a case and opportunity status is updated
      Reference_Advisor_Select__c refadv1 = new Reference_Advisor_Select__c(Account_Name__c='Test Acct'
                                                    ,Paychex_Case_Nbr__c=c.CaseNumber);
      insert refadv1;   
      Reference_Advisor_Select__c refadv1_ans = [Select Case_Lookup__c, Message_from_ePlan__c from Reference_Advisor_Select__c 
                    where Paychex_Case_Nbr__c = :c.CaseNumber];
      System.assertEquals(c.Id, refadv1_ans.Case_Lookup__c);
      System.assertEquals(Null, refadv1_ans.Message_from_ePlan__c);
          
      Opportunity o = [Select Id, Stagename from Opportunity where Id = :oppty1.Id];
      System.assertEquals('Sold', o.StageName);
          
      // test for reference object not to be linked to a case
      Reference_Advisor_Select__c refadv2 = new Reference_Advisor_Select__c(Account_Name__c='Test Acct'
                                                    ,Paychex_Case_Nbr__c='123');

      insert refadv2;
      Reference_Advisor_Select__c refadv2_ans = [Select Case_Lookup__c, Message_from_ePlan__c from Reference_Advisor_Select__c 
                    where Paychex_Case_Nbr__c = '123'];
      System.assertEquals(Null, refadv2_ans.Case_Lookup__c);
      System.assertEquals('Bad case from ePlan, can not find case to link to', refadv2_ans.Message_from_ePlan__c); 
    }// end createTestAccounts                 
      
      static testmethod void test2() {
      // create an account
      Account acct = new Account(Name='Test Acct');
      insert acct;
      
      // create another 401k opportunity
      Schema.RecordTypeInfo opptyRt2 = RecordTypeHelper.getRecordType('HRS 401(k) Opportunity FSS Record Type','Opportunity');
      Opportunity oppty2 = new Opportunity(Name='Test Opporty', RecordTypeId=opptyRt2.getRecordTypeId()
                                         ,AccountId=acct.Id
                                         ,StageName='Pending'
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=UserInfo.getUserId());
      insert oppty2;
        
      // mark opportunity as sold so case is created    
      oppty2.StageName = 'Sold';
      oppty2.Service_Location__c = OpportunityCreateCase.ADVFSA_SERVICE_CENTER;
      update oppty2;
      System.assertEquals(1,[Select count() from Case where Opportunity__c=:oppty2.Id]);

      Case c2 = [SELECT Id, CaseNumber from Case where Opportunity__c = :oppty2.Id];
      // test for reference object not to be linked to a case
      
      Reference_Advisor_Select__c refadv2 = new Reference_Advisor_Select__c(Account_Name__c='Test Acct'
                                                    ,Paychex_Case_Nbr__c='123');

      insert refadv2;
      
      // test onUpdate to link to a case and opportunity status is updated
      refadv2.Paychex_Case_Nbr__c = c2.CaseNumber;
      update refadv2;
      Reference_Advisor_Select__c refadv2_ans2 = [Select Case_Lookup__c, Message_from_ePlan__c from Reference_Advisor_Select__c 
                    where Paychex_Case_Nbr__c = :c2.CaseNumber];      
      System.assertEquals(c2.Id, refadv2_ans2.Case_Lookup__c);
      System.assertEquals(Null, refadv2_ans2.Message_from_ePlan__c);
 
      Opportunity o2 = [Select Id, Stagename from Opportunity where Id = :oppty2.Id];  
      System.assertEquals('Sold', o2.Stagename);
      
    }   //end   test2
      
                    
}