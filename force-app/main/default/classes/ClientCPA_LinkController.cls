/* 
 * Provide ability to search for Client and CPA and link them together.
 *
 * History
 * -------
 * 09/23/2011 Dan Carmen        Created.
   10/29/2018 Dan Carmen   Increment API to version 44

 */
public with sharing class ClientCPA_LinkController {

   private final Client_CPA_Link__c linkRecord;  

   public ReferralSearch refSearch{get;set;}
   
   public AccountSearch acctSearch{get;set;}
   
   public ClientCPA_LinkController(ApexPages.StandardController  
                               stdController) {  
      linkRecord = (Client_CPA_Link__c)stdController.getRecord();
      
      refSearch = new ReferralSearch();  
      refSearch.linkRecord = linkRecord;
      
      acctSearch = new AccountSearch();
      acctSearch.linkRecord = linkRecord;
   } // ClientCPA_LinkController

   public PageReference searchRecords() {
      // verify both referral and client fields filled in   	
   	  refSearch.searchRfrls();
   	  // search clients
   	  acctSearch.searchAccts();
      return null;
   }

   public Boolean searchPerformed{
   	  // this will have to include client search also
      get {return (refSearch.searchPerformed && acctSearch.searchPerformed);}
   } // searchPerformed
   

} // class ClientCPA_LinkController