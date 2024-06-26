/* 
 * Methods used for searching for an Account.
 *
 * History
 * -------
 * 11/21/2010 Dan Carmen   Created
   10/29/2018 Dan Carmen   Increment API to version 44

 */
public without sharing class AccountSearch {

   public AccountSearch() {
      searchPerformed = false;
   } // AccountSearch
   
   public Client_CPA_Link__c linkRecord{get; set;}
   
   /** Is the client field populated with at least one character. */
   public Boolean hasName {
   	  get {return (linkRecord != null &&  linkRecord.Client_Name__c != null && linkRecord.Client_Name__c.length() > 0);}
   } // hasName
   
   /** Is the payroll branch number field populated with at least one character. */
   public Boolean hasBranchNumber {
   	  get {
   	  	 // remove leading zeroes
   	  	 if (linkRecord != null &&  linkRecord.Payroll_Branch_Number__c != null && linkRecord.Payroll_Branch_Number__c.startsWith('0')) {
            while (linkRecord.Payroll_Branch_Number__c.length() > 0 && linkRecord.Payroll_Branch_Number__c.startsWith('0')) {
               linkRecord.Payroll_Branch_Number__c = linkRecord.Payroll_Branch_Number__c.substring(1);
            }
   	  	 } // if   	  	
   	  	 return (linkRecord != null &&  linkRecord.Payroll_Branch_Number__c != null && linkRecord.Payroll_Branch_Number__c.length() > 0);
   	  }
   } // hasBranchNumber
   
   /** Is the payroll client number field populated with at least one character. */
   public Boolean hasClientNumber {
   	  get {return (linkRecord != null &&  linkRecord.Payroll_Client_Number__c != null && linkRecord.Payroll_Client_Number__c.length() > 0);}
   } // hasClientNumber
   
   /** Is the postal code field populated with at least one character. */
   public Boolean hasPostalCode {
   	  get {return (linkRecord != null &&  linkRecord.Client_Postal_Code__c != null && linkRecord.Client_Postal_Code__c.length() > 0);}
   } // hasPostalCode
   
   /** Check that a minimal combination of fields are filled out in order to attempt a search.
    */
   private Boolean checkReqFields() {
   	  // the minimum combinations to have to perform a search
   	  if ((hasName && hasPostalCode) || hasClientNumber || (hasName && hasBranchNumber)) {
   	  	 return true;
   	  }

      ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Please enter valid client search criteria. The following are the minimum combinations: name and postal code/ payroll client number/ name and payroll branch number'));
      return false;
   } // checkReqFields
   
   public Boolean hasSearchResults{
      get {return (searchResults != null && searchResults.size() > 0);}
   } // hasSearchResults
   
   public Boolean searchPerformed{get;private set;}
   
   public List<Account> searchResults{get;private set;}
   
   /** Search for Accounts.
    */
   public Boolean searchAccts() {
   	  Boolean okay = true;
   	  if (checkReqFields()) {
   	     String query = buildSearchQuery();
         SObject[] results = Database.query(query);
         searchResults = (Account[])results;
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'nbr results='+searchResults.size()+' query='+query));
         searchPerformed = true;
   	  } else {
   	     okay = false;
   	  }
      return okay;
   } // searchAccts
   
   public String buildSearchQuery() {
   	  String query = 'Select Id, Name, AccountNumber ';
   	  query += ',Bis_ID__c ';
   	  query += ',BillingStreet, BillingPostalCode ';
   	  query += ',ShippingStreet, ShippingPostalCode ';
   	  query += ',CPA_Name_Ref__c, CPA_Name_Ref__r.Name ';
   	  query += ' FROM Account ';
   	  String whereOperand = ' WHERE ';
   	  if (hasName) {
   	  	 query += whereOperand+' Name like \'%'+String.escapeSingleQuotes(linkRecord.Client_Name__c)+'%\' ';
   	  	 whereOperand = ' AND ';
   	  }
   	  if (hasBranchNumber) {
   	  	 query += whereOperand+' AccountNumber like \''+String.escapeSingleQuotes(linkRecord.Payroll_Branch_Number__c)+'-%\' ';
   	  	 whereOperand = ' AND ';
   	  }
   	  if (hasClientNumber) {
   	  	 query += whereOperand+' AccountNumber like \'%-'+String.escapeSingleQuotes(linkRecord.Payroll_Client_Number__c)+'\' ';
   	  	 whereOperand = ' AND ';
   	  }
   	  if (hasPostalCode) {
   	  	 query += whereOperand+'( BillingPostalCode like \''+String.escapeSingleQuotes(linkRecord.Client_Postal_Code__c)+'%\' ';
   	  	 query += ' OR ShippingPostalCode like\''+String.escapeSingleQuotes(linkRecord.Client_Postal_Code__c)+'%\' ) ';
   	  	 whereOperand = ' AND ';
   	  }
   	  query += ' limit 100';
   	  return query;
   } // buildSearchQuery


} // class AccountSearch