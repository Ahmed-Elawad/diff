/* 
 * Tests for the RiskRedFlagController.
 *
 * History
 * -------
 * 02/22/2011 Dan Carmen        Created.
   10/26/2018 Dan Carmen        Increment API version - not sure that we actually need this anymore
   09/08/2021 Carrie Marciano	Commented out for Forseva uninstall

 */
@isTest
private class RiskRedFlagControllerTest {

 /*
   /* Create a NewUserExtension object.
   private static RiskRedFlagController getController(String acctId) {
      Test.SetCurrentPageReference(New PageReference('Page.RiskRedFlag'));
      if (acctId != null) {
         System.CurrentPageReference().getParameters().put('id',acctId);
      }
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(new Account());
      RiskRedFlagController rrfg = new RiskRedFlagController(sc1);
      return rrfg;
   } // getController
*/

   static testMethod void test() {
   	  RiskRedFlagController rrfc = new RiskRedFlagController();
   } // testNoAccount

/*    
   private static Risk_Red_Flag__c[] setupRisks() {
   	  Risk_Red_Flag__c[] risks = new Risk_Red_Flag__c[]{};
   	  risks.add(new Risk_Red_Flag__c(Start_Date__c=Date.today().addMonths(-12)
   	                                ,End_Date__c=Date.today().addMonths(24)
   	                                ,Sort_Order__c=1000
   	                                ,Risk_Area__c='Test'
   	                                ,Description__c='Test Risk 1'));
   	  risks.add(new Risk_Red_Flag__c(Start_Date__c=Date.today().addMonths(-12)
   	                                ,End_Date__c=Date.today().addMonths(24)
   	                                ,Sort_Order__c=1010
   	                                ,Risk_Area__c='Test'
   	                                ,Description__c='Test Risk 2'));
   	  risks.add(new Risk_Red_Flag__c(Start_Date__c=Date.today().addMonths(-12)
   	                                ,End_Date__c=Date.today().addMonths(24)
   	                                ,Sort_Order__c=1020
   	                                ,Risk_Area__c='Test'
   	                                ,Description__c='Test Risk 3'));
   	  insert risks;
   	  return risks;
   } // setupRisks
    
   /* Test saving with no risks selected.
   static testMethod void testAccountNoneSelected() {
   	  Account acct = new Account(name='Test Account');
   	  insert acct;
   	  setupRisks();
   	  RiskRedFlagController rrfc = getController(acct.Id);
   	  System.assertEquals(true,rrfc.hasAcct);
   	  // should be at least 3 flags present
   	  System.assertEquals(true,rrfc.displayFlags.size() >= 3);

   	  // verify no messages
      System.assertEquals(false,ApexPages.hasMessages());
   	  // try saving with nothing selected
   	  PageReference result = rrfc.saveRequest();
   	  // no PageReference should be returned
   	  System.assertEquals(null,result);
   	  // should be a warning
      System.assertEquals(true,ApexPages.hasMessages());
      // cancel
      result = rrfc.cancel();
      // cancel returns to the account
   	  System.assertEquals(true,result.getUrl().contains(acct.Id));
      
   } // testAccountNoneSelected
    
   /* Test saving with risks selected.
   static testMethod void testAccountSelected() {
   	  Account acct = new Account(name='Test Account');
   	  insert acct;
   	  setupRisks();
   	  RiskRedFlagController rrfc = getController(acct.Id);
   	  System.assertEquals(true,rrfc.hasAcct);
   	  // should be at least 3 flags present
   	  System.assertEquals(true,rrfc.displayFlags.size() >= 3);

   	  // verify no messages
      System.assertEquals(false,ApexPages.hasMessages());
      
      // select the first three risks
      rrfc.displayFlags[0].checked = true;
      rrfc.displayFlags[1].checked = true;
      rrfc.displayFlags[2].checked = true;
      // add additional information
      rrfc.addInfo = 'Here is some additional information';
      
   	  // save the page
   	  PageReference result = rrfc.saveRequest();
   	  // The returning URL should return to the account
   	  System.assertEquals(true,result.getUrl().contains(acct.Id));
   	  // should be no warnings
      //System.assertEquals(true,ApexPages.hasMessages());
      
      // select the data and verify present
      Case c = [Select Id,RecordTypeId
                          ,AccountId
                          ,Type
                          ,Origin
                          ,Priority 
                          ,Status 
                          ,Current_Step__c 
                          ,User__c 
                          ,Subject
                   from Case where AccountId = :acct.Id];
      System.assertEquals('Escalation',c.Type);                   
      System.assertEquals('Red Flag',c.Origin);                   
      System.assertEquals('High',c.Priority);                   
      System.assertEquals('New',c.Status);                   
      System.assertEquals('Case Creation',c.Current_Step__c);                   
      System.assertEquals(UserInfo.getUserId(),c.User__c);                   
      System.assertEquals(true,(c.Subject.startsWith('Red Flag Escalaton -')));                   
      
      // verify Reference object
      Reference_Credit_Risk__c rcr = [Select Id, Type__c, Red_Flag_Reason__c from Reference_Credit_Risk__c where Case__c = :c.Id];
      System.assertEquals('Red Flag Escalation',rcr.Type__c);
      // verify information is in the reason field
      System.assertEquals(true,(rcr.Red_Flag_Reason__c.contains('Here is some additional information')));
      System.assertEquals(true,(rcr.Red_Flag_Reason__c.contains(rrfc.displayFlags[0].flag.Description__c)));
      System.assertEquals(true,(rcr.Red_Flag_Reason__c.contains(rrfc.displayFlags[1].flag.Description__c)));
      System.assertEquals(true,(rcr.Red_Flag_Reason__c.contains(rrfc.displayFlags[2].flag.Description__c)));
      
   } // testAccountSelected
    
   /* Test saving with risks selected.
   static testMethod void testBadAcctId() {
   	  Account acct = new Account(name='Test Account');
   	  insert acct;
   	  setupRisks();
   	  RiskRedFlagController rrfc = getController(acct.Id+'7');
   	  System.assertEquals(false,rrfc.hasAcct);
   }

*/    
} // class RiskRedFlagControllerTest