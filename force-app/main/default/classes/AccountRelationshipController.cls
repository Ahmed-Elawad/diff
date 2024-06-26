/* 
 *The methods used for displaying clients that are grouped together in some way.
 *
 * History
 * -------
 * 07/31/2009 Dan Carmen   Created
   06/02/2014 Dan Carmen   Changed API version to 30
 *
 */
public with sharing class AccountRelationshipController {

   public AccountRelationshipController() {
   	  // the type of relationship this is
   	  rltnType = System.currentPageReference().getParameters().get('rltnType');
   	  // the value of the key field for this relationship
      String rltnKey = System.currentPageReference().getParameters().get('key');
      
      // the id of the Account this page was called from
      Id id = System.currentPageReference().getParameters().get('id');
      //ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.INFO, 'rltnType='+rltnType+' rltnKey='+rltnKey+' id='+id);
      //ApexPages.addMessage(myMsg);
      
      if (id != null) {
         thisAcct = [SELECT Id, Name, AccountNumber
                  FROM Account WHERE Id=:id];
      }
      setAccts(rltnKey);
   } // AccountRelationshipController

   private Account thisAcct = null;
   
   public Account getThisAcct() {
   	  return thisAcct;
   } // getThisAcct
   
   private String rltnType = null;
   
   /** Based on the type passed in, return the title of the relationship to display to the user.
    */
   public String getDisplayTitle() {
   	  if (rltnType != null) {
   	  	 if (rltnType == 'premRelated') {
   	  	 	return 'Premier Related Company';
   	  	// } else if (rltnType == 'hroGrp') {
   	  	// 	return 'HRO Group';
   	  	 }
   	  } else if (rltnType == null) {
   	  	 return 'No relation type was passed in!';
   	  }
   	  return 'No Title is set for type '+rltnType;
   } // getDisplayTitle

   public String getAccountinfo() {
   	  if (thisAcct != null) {
   	     return(thisAcct.AccountNumber+' '+thisAcct.Name);
   	  }
   	  return 'The Prospect-Client was not set!';
   } // getAccountInfo
   
   /** Get the title for the section.
    */
   public String getSectionTitle() {
   	  if ((rltnType != null) && (thisAcct != null)) {
   	  	 if (rltnType == 'premRelated') {
   	  	 	return 'Premier Related Companies for '+getAccountinfo();
   	  	// } else if (rltnType == 'hroGrp') {
   	  	// 	return 'HRO Group for '+getAccountinfo();
   	  	 }
   	  } else if (rltnType == null) {
   	  	 return 'No relation type was passed in!';
   	  } else if (thisAcct == null) {
   	  	 return 'The Prospect-Client was not set on the page.';
   	  }
   	  return 'No Title is set for type '+rltnType;
   } // getSectionTitle
   
   private static final String PREM_RELATED='Premier Related Company';
   
   /** Get the value of the relationship type used for the SOQL statement.
    */
   private String getSOQLRltnType() {
   	  if (rltnType != null) {
   	  	 // for the premier related company
   	  	 if (rltnType == 'premRelated') {
   	  	 	return PREM_RELATED;
   	  	 }
   	  } // if (rltnType != null
   	  return (rltnType == null ? '' : rltnType);
   } // getSOQLRltnType
   
   private List<Account> accts = null;
   
   /** Get the accounts found for the relationship.
    */
   public List<Account> getAccts() {
   	  return accts;
   } // getAccts
   
   private void setAccts(String rltnKey) {
   	  String rltnType = getSOQLRltnType();
      //ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.INFO, 'set Accts rltnType='+rltnType);
      //ApexPages.addMessage(myMsg);
   	  if ((rltnType != '') && (rltnKey != null) && (thisAcct != null)) {
   	  	 if (rltnType == PREM_RELATED) {
   	  	 	// remove commas from key
   	  	 	rltnKey = rltnKey.replace(',', '');
            //ApexPages.Message myMsg2 = new ApexPages.Message(ApexPages.severity.INFO, 'getting accounts rltnKey='+rltnKey);
            //ApexPages.addMessage(myMsg2);
            List<Account_Relationship__c> rltns = new List<Account_Relationship__c>([select Id
   	                                                                                      ,Account_Relationship_Id__c
   	                                                                                      ,Account__c
   	                                                                                      ,Name
   	                                                                                      ,Relationship_Key__c
   	                                                                                      ,Relationship_Type__c
   	                                                                                      ,Account__r.Id
   	                                                                                      ,Account__r.Name
   	                                                                                      ,Account__r.AccountNumber 
   	                                                                                  from Account_Relationship__c where Relationship_Key__c = :rltnKey and Relationship_Type__c = :rltnType]);
            accts = new List<Account>();
            for (Account_Relationship__c ar : rltns) {
            	accts.add(ar.account__r);
            } // for (Account_Relationship__c                                                 
            //myMsg2 = new ApexPages.Message(ApexPages.severity.INFO, 'number of accounts found='+accts.size());
            //ApexPages.addMessage(myMsg2);
   	  //	 } else if (rltnType == 'hroGrp') {
   	  //	 	accts = new List<Account>([Select Id, Name, AccountNumber
   	  //	 	                             from Account
   	  //	 	                            where HRO_Number__c = :rltnKey]);
   	  	 } // if (rltnType ==    	                                                                                  
   	  } // if ((rltnType
   } // setRltns
   
   /** Are any accounts setup to view? 
    */
   public boolean getHasAccts() {
   	  return (accts != null && accts.size() > 0);
   } // getHasAccts
   
} // class AccountRelationshipController