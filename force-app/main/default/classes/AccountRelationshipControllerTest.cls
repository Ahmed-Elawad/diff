/* 
 *The test methods for the AccountRelationshipController class.
 *
 * History
 * -------
 * 07/31/2009 Dan Carmen   Created
   06/02/2014 Dan Carmen   Changed API version to 30
 *
 */
@isTest
private class AccountRelationshipControllerTest {

   static testMethod void testRelatedClients() {
      // create a client with a bis client id
      Account acct1 = new Account(Name='Acct Relationship Test1'
   	      ,AccountNumber='17-TEST1'
            ,Bis_ID__c=123456);
      insert acct1;

      // create other clients that will be related
      Account acct2 = new Account(Name='Acct Relationship Test2'
   	      ,AccountNumber='17-TEST2'
            ,Bis_ID__c=123457);
      Account acct3 = new Account(Name='Acct Relationship Test3'
   	      ,AccountNumber='17-TEST3'
            ,Bis_ID__c=123458);
      Account acct4= new Account(Name='Acct Relationship Test4'
   	      ,AccountNumber='17-TEST4'
            ,Bis_ID__c=123459);
      insert acct2;
      insert acct3;
      insert acct4;
        
      // create account relationship records for other clients
      Account_Relationship__c ar1 = new Account_Relationship__c(Account__c=acct2.Id
                                    ,Relationship_Key__c=acct1.Bis_ID__c+''
                                    ,Relationship_Type__c='Premier Related Company');

      Account_Relationship__c ar2 = new Account_Relationship__c(Account__c=acct3.Id
                                    ,Relationship_Key__c=acct1.Bis_ID__c+''
                                    ,Relationship_Type__c='Premier Related Company');

      Account_Relationship__c ar3 = new Account_Relationship__c(Account__c=acct4.Id
                                    ,Relationship_Key__c=acct1.Bis_ID__c+''
                                    ,Relationship_Type__c='Premier Related Company');

      insert ar1;
      insert ar2;
      insert ar3;
        
      /*******************************
         test with no parameters
       *******************************/
      ApexPages.currentPage().getParameters().clear();                            
   	AccountRelationshipController arc = new AccountRelationshipController();
   	System.assertEquals(arc.getDisplayTitle(),'No relation type was passed in!'); 
      System.assertEquals(arc.getSectionTitle(),'No relation type was passed in!'); 
    	System.assertEquals(arc.getThisAcct(),null);
    	System.assertEquals(arc.getAccountinfo(),'The Prospect-Client was not set!');
    	System.assertEquals(arc.getAccts(),null);
    	System.assertEquals(arc.getHasAccts(),false);

      /*******************************
         test with invalid rltnType, no key or id
       *******************************/
      ApexPages.currentPage().getParameters().clear();                            
      ApexPages.currentPage().getParameters().put('rltnType', 'testType');
   	arc = new AccountRelationshipController();
   	System.assertEquals(arc.getDisplayTitle(),'No Title is set for type testType'); 
      System.assertEquals(arc.getSectionTitle(),'The Prospect-Client was not set on the page.'); 
    	System.assertEquals(arc.getThisAcct(),null);
    	System.assertEquals(arc.getAccountinfo(),'The Prospect-Client was not set!');
    	System.assertEquals(arc.getAccts(),null);
    	System.assertEquals(arc.getHasAccts(),false);

      /*******************************
         test with valid rltnType, no key or id
       *******************************/
      ApexPages.currentPage().getParameters().clear();                            
      ApexPages.currentPage().getParameters().put('rltnType', 'premRelated');
   	arc = new AccountRelationshipController();
   	System.assertEquals(arc.getDisplayTitle(),'Premier Related Company'); 
      System.assertEquals(arc.getSectionTitle(),'The Prospect-Client was not set on the page.'); 
    	System.assertEquals(arc.getThisAcct(),null);
    	System.assertEquals(arc.getAccountinfo(),'The Prospect-Client was not set!');
    	System.assertEquals(arc.getAccts(),null);
    	System.assertEquals(arc.getHasAccts(),false);
        
      /*******************************
         test with key, no rltnType or id
       *******************************/
      ApexPages.currentPage().getParameters().clear();                            
      ApexPages.currentPage().getParameters().put('key', acct1.Bis_ID__c+'');
   	arc = new AccountRelationshipController();
   	System.assertEquals(arc.getDisplayTitle(),'No relation type was passed in!'); 
      System.assertEquals(arc.getSectionTitle(),'No relation type was passed in!'); 
    	System.assertEquals(arc.getThisAcct(),null);
    	System.assertEquals(arc.getAccountinfo(),'The Prospect-Client was not set!');
    	System.assertEquals(arc.getAccts(),null);
    	System.assertEquals(arc.getHasAccts(),false);
        

      /*******************************
         test with id, no key or rltnType 
       *******************************/
      ApexPages.currentPage().getParameters().clear();                            
      ApexPages.currentPage().getParameters().put('id', acct1.Id);
   	arc = new AccountRelationshipController();
   	System.assertEquals(arc.getDisplayTitle(),'No relation type was passed in!'); 
      System.assertEquals(arc.getSectionTitle(),'No relation type was passed in!'); 
    	System.assertEquals(arc.getThisAcct().Id,acct1.Id);
    	System.assertEquals(arc.getAccountinfo(),acct1.AccountNumber+' '+acct1.Name);
    	System.assertEquals(arc.getAccts(),null);
    	System.assertEquals(arc.getHasAccts(),false);
        
      /*******************************
         test with rltnType and key, not id
       *******************************/
      ApexPages.currentPage().getParameters().clear();                            
      ApexPages.currentPage().getParameters().put('rltnType', 'premRelated');
      ApexPages.currentPage().getParameters().put('key', acct1.Bis_ID__c+'');
   	arc = new AccountRelationshipController();
   	System.assertEquals(arc.getDisplayTitle(),'Premier Related Company'); 
      System.assertEquals(arc.getSectionTitle(),'The Prospect-Client was not set on the page.'); 
    	System.assertEquals(arc.getThisAcct(),null);
    	System.assertEquals(arc.getAccountinfo(),'The Prospect-Client was not set!');
    	System.assertEquals(arc.getAccts(),null);
    	System.assertEquals(arc.getHasAccts(),false);
        
      /*******************************
         test with rltnType and id, no key
       *******************************/
      ApexPages.currentPage().getParameters().clear();                            
      ApexPages.currentPage().getParameters().put('rltnType', 'premRelated');
      ApexPages.currentPage().getParameters().put('id', acct1.Id);
   	arc = new AccountRelationshipController();
   	System.assertEquals(arc.getDisplayTitle(),'Premier Related Company'); 
      System.assertEquals(arc.getSectionTitle(),'Premier Related Companies for '+acct1.AccountNumber+' '+acct1.Name); 
    	System.assertEquals(arc.getThisAcct().Id,acct1.Id);
    	System.assertEquals(arc.getAccountinfo(),acct1.AccountNumber+' '+acct1.Name);
    	System.assertEquals(arc.getAccts(),null);
    	System.assertEquals(arc.getHasAccts(),false);
        
      /*******************************
         test with key and id, no rltnType
       *******************************/
      ApexPages.currentPage().getParameters().clear();                            
      ApexPages.currentPage().getParameters().put('key', acct1.Bis_ID__c+'');
      ApexPages.currentPage().getParameters().put('id', acct1.Id);
   	arc = new AccountRelationshipController();
  	   System.assertEquals(arc.getDisplayTitle(),'No relation type was passed in!'); 
      System.assertEquals(arc.getSectionTitle(),'No relation type was passed in!'); 
    	System.assertEquals(arc.getThisAcct().Id,acct1.Id);
    	System.assertEquals(arc.getAccountinfo(),acct1.AccountNumber+' '+acct1.Name);
    	System.assertEquals(arc.getAccts(),null);
    	System.assertEquals(arc.getHasAccts(),false);
        
        /*******************************
           test with rltnType, key, id
         *******************************/
        ApexPages.currentPage().getParameters().clear();                            
        ApexPages.currentPage().getParameters().put('rltnType', 'premRelated');
        ApexPages.currentPage().getParameters().put('key', acct1.Bis_ID__c+'');
        ApexPages.currentPage().getParameters().put('id', acct1.Id);
   	    arc = new AccountRelationshipController();
   	    
   	    System.assertEquals(arc.getDisplayTitle(),'Premier Related Company'); 
        System.assertEquals(arc.getSectionTitle(),'Premier Related Companies for '+acct1.AccountNumber+' '+acct1.Name); 
    	System.assertEquals(arc.getThisAcct().Id,acct1.Id);
    	System.assertEquals(arc.getAccountinfo(),acct1.AccountNumber+' '+acct1.Name);
    	List<Account> accts = arc.getAccts();
    	System.assertEquals(accts.size(),3);
    	System.assertEquals(arc.getHasAccts(),true);
    	    
        
      /*******************************
         test with acct and no relationships
       *******************************/
      ApexPages.currentPage().getParameters().clear();                            
      ApexPages.currentPage().getParameters().put('rltnType', 'premRelated');
      ApexPages.currentPage().getParameters().put('key', acct2.Bis_ID__c+'');
      ApexPages.currentPage().getParameters().put('id', acct2.Id);
   	arc = new AccountRelationshipController();
   	    
   	System.assertEquals(arc.getDisplayTitle(),'Premier Related Company'); 
      System.assertEquals(arc.getSectionTitle(),'Premier Related Companies for '+acct2.AccountNumber+' '+acct2.Name); 
    	System.assertEquals(arc.getThisAcct().Id,acct2.Id);
    	System.assertEquals(arc.getAccountinfo(),acct2.AccountNumber+' '+acct2.Name);
    	accts = arc.getAccts();
    	System.assertEquals(accts.size(),0);
    	System.assertEquals(arc.getHasAccts(),false);

      /*******************************
         test with rltnType, key, id, rltnType not valid
       *******************************/
      ApexPages.currentPage().getParameters().clear();                            
      ApexPages.currentPage().getParameters().put('rltnType', 'testRltnType');
      ApexPages.currentPage().getParameters().put('key', acct1.Bis_ID__c+'');
      ApexPages.currentPage().getParameters().put('id', acct1.Id);
   	arc = new AccountRelationshipController();
   	    
   	System.assertEquals(arc.getDisplayTitle(),'No Title is set for type testRltnType'); 
      System.assertEquals(arc.getSectionTitle(),'No Title is set for type testRltnType'); 
    	System.assertEquals(arc.getThisAcct().Id,acct1.Id);
    	System.assertEquals(arc.getAccountinfo(),acct1.AccountNumber+' '+acct1.Name);
    	System.assertEquals(arc.getAccts(),null);
    	System.assertEquals(arc.getHasAccts(),false);
    	    

    } // testRelatedClients
    
} // class AccountRelationshipControllerTest