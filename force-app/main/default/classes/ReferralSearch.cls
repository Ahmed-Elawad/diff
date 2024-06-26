/*
 *  This class can be used to search for Referral Account or Referral Contacts.  
 *
 * History
 * --------
 * 11/22/2011   Dan Carmen  created
 * 05/22/2013   Cindy Freeman   added methods to search for Referral Account or Referral Contact
 * 01/08/2014   Justin Stouffer Added Employee_Number__c to RefContact query.   
 * 01/14/2014   Cindy Freeman   fixed shortening of referral account name for query 
 * 10/29/2018   Dan Carmen   Increment API to version 44
 * 11/08/2021 Jermaine Stukes	Removed references to external wholesaler owner fields

 */

public with sharing class ReferralSearch {

   public ReferralSearch() {
      searchPerformed = false;
   } // ReferralSearch
   
   public Client_CPA_Link__c linkRecord{get; set;}
   
   /** Is the first name field populated with at least one character. */
   public Boolean hasFirst {
      get {return (linkRecord != null &&  linkRecord.First_Name__c != null && linkRecord.First_Name__c.length() > 0);}
   } // hasFirst
   
   /** Is the last name field populated with at least one character. */
   public Boolean hasLast {
      get {return (linkRecord != null &&  linkRecord.Last_Name__c != null && linkRecord.Last_Name__c.length() > 0);}
   } // hasLast
   
   /** Is the email field populated with at least one character. */
   public Boolean hasEmail {
      get {return (linkRecord != null &&  linkRecord.Email__c != null && linkRecord.Email__c.length() > 0);}
   } // hasEmail
   
   /** Is the phone field populated with at least one character. */
   public Boolean hasPhone {
      get {return (linkRecord != null &&  linkRecord.Phone__c != null && linkRecord.Phone__c.length() > 0);}
   } // hasEmail
   
   /** Is the account name field populated with at least one character. */
   public Boolean hasAcctName {
      get {return (linkRecord != null &&  linkRecord.Referral_Account_Name__c != null && linkRecord.Referral_Account_Name__c.length() > 0);}
   } // hasAcctName
   
   /** Is the zip code field populated with at least one character. */
   public Boolean hasZip {
      get {return (linkRecord != null &&  linkRecord.Postal_Code__c != null && linkRecord.Postal_Code__c.length() > 0);}
   } // hasZip
   
   
   /** Check that a minimal combination of fields are filled out in order to attempt a search.
    */
   private Boolean checkReqFields() {
      // the minimum combinations to have to perform a search
      // email
      // phone
      // account name
      // first and last name
      // last name and zip code
      if (hasEmail || hasPhone || hasAcctName || (hasFirst && hasLast) || (hasLast && hasZip)) {
         return true;
      }

      ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Please enter valid search criteria. The following are the minimum combinations: email/ phone/ account name/ first and last name/ last name and zip code'));
      return false;
   } // checkReqFields
   
   public Boolean hasSearchResults{
      get {return (searchResults != null && searchResults.size() > 0);}
   } // hasSearchResults
   
   public Boolean searchPerformed{get;private set;}
   
   public List<Referral_Contact__c> searchResults{get;private set;}
   
   /** Search to see if existing referral.
    */
   public Boolean searchRfrls() {
      Boolean okay = true;
      if (checkReqFields()) {
         String query = buildSearchQuery();
         SObject[] results = Database.query(query);
         searchResults = (Referral_Contact__c[])results;
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'nbr results='+searchResults.size()+' query='+query));
         searchPerformed = true;
      } else {
         okay = false;
      }
      return okay;
   } // searchRfrls
   
   public String buildSearchQuery() {
      String query = 'Select Id, Name, First_Name__c, Last_Name__c, Phone__c, Email__c ';
      query += ',OwnerId, Owner.Name ';
      query += ',Referral_Account__r.Name, Referral_Account__r.Street_Address_1__c, Referral_Account__r.City__c ';
      query += ',Referral_Account__r.State_Province__c, Referral_Account__r.Zip_Postal_Code__c ';
      query += ',Referral_Account__r.OwnerId, Referral_Account__r.Owner.Name ';
      query += ' FROM Referral_Contact__c ';
      String whereOperand = ' WHERE ';
      if (hasPhone) {
         query += whereOperand+' Phone__c=\''+String.escapeSingleQuotes(linkRecord.Phone__c)+'\' ';
         whereOperand = ' AND ';
      }
      if (hasEmail) {
         query += whereOperand+' Email__c=\''+String.escapeSingleQuotes(linkRecord.Email__c)+'\' ';
         whereOperand = ' AND ';
      }
      if (hasFirst) {
         query += whereOperand+' Name like\'%'+String.escapeSingleQuotes(linkRecord.First_Name__c)+'%\' ';
         whereOperand = ' AND ';
      }
      if (hasLast) {
         query += whereOperand+' Name like\'%'+String.escapeSingleQuotes(linkRecord.Last_Name__c)+'%\' ';
         whereOperand = ' AND ';
      }
      if (hasAcctName) {
         query += whereOperand+' Referral_Account__r.Name like\'%'+String.escapeSingleQuotes(linkRecord.Referral_Account_Name__c)+'%\' ';
         whereOperand = ' AND ';
      }
      if (hasZip) {
         query += whereOperand+' Referral_Account__r.Zip_Postal_Code__c like\''+String.escapeSingleQuotes(linkRecord.Postal_Code__c)+'%\' ';
         whereOperand = ' AND ';
      }
      query += ' limit 100';
      return query;
   } // buildSearchQuery
   
   
   public List<Referral_Account__c> searchRefAcctResults{get;private set;}

   public String buildRefAcctSearchQuery(String acctName, String acctStreet, String acctZip) {
      
      String shortName = acctName.substring(0,(Integer)(acctName.length() * .7));               // want to match 70% of name      
      String streetNo = acctStreet.substringBefore(' ');                                        // want to match just street number
      String zip5 = (acctZip.length() > 5) ? acctZip.substring(0,4) : acctZip;                  // want to match just zip 5
      
      String query = 'Select Id, Name, Owner.Id, Phone__c, Street_Address_1__c, Street_Address_2__c, City__c, State_Province__c, Zip_Postal_Code__c';
      query += ', Internal_Wholesaler_Account_Owner__c, HRS_Account_Owner__c, OwnerId, Owner.Name ';
      query += ' FROM Referral_Account__c ';
      String whereOperand = ' WHERE ';
      if (shortName != null)
      {     query += whereOperand+' Name like\'%'+String.escapeSingleQuotes(shortName)+'%\' ';
            whereOperand = ' AND ';
      }
      if (streetNo != null)
      {     query += whereOperand+' Street_Address_1__c like\'%'+String.escapeSingleQuotes(streetNo)+'%\' ';
            whereOperand = ' AND ';
      }
      if (zip5 != null)
      {     query += whereOperand+' Zip_Postal_Code__c like\'%'+String.escapeSingleQuotes(zip5)+'%\' ';
            whereOperand = ' AND ';
      }
      query += ' limit 100';
      return query;
   } // buildRefAcctSearchQuery
     
      /** Search to see if referral account exists based on partial company name, street number and zip5.
    */ 
   public Boolean searchRfrlAccts(String acctName, String acctStreet, String acctZip) {
        Boolean okay = true;
        String query = buildRefAcctSearchQuery(acctName, acctStreet, acctZip);
       
        SObject[] results = Database.query(query);
        searchRefAcctResults = (Referral_Account__c[])results;        
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'nbr results='+searchResults.size()+' query='+query));

        okay = (searchRefAcctResults.size() > 0 ? true : false);
        return okay;
   } // searchRfrlAccts
   

     /** Query for referral contacts that go with Referral account you just found.  Then pick 1 ref contact that matches who you are looking for
    */
    public List<Referral_Contact__c> searchRefCtctResults{get;private set;}

    public Referral_Contact__c searchRfrlCtct(Id refAcctId, String ctctFullName, String ctctLastName, String ctctPhone, String ctctEmail) {
        String ctctSquishedPhone = Utilities.removeExtraChars(ctctPhone, '0123456789');       
        Referral_Contact__c foundRefCt;
        searchRefCtctResults = [Select Id, Name, Last_Name__c, LastName__c, Phone__c, Email__c, Owner.Id,
                             Internal_Wholesaler_Contact_Owner__c, Employee_Number__c
                             , End_Date__c, Referral_Account__r.HRS_Account_Owner__c, Referral_Account__r.Owner.Id
                             , Referral_Account__r.End_Date__c from Referral_Contact__c 
                             WHERE Referral_Account__c = :refAcctId order by createdDate DESC];
        
        for (Referral_Contact__c refct: searchRefCtctResults)
        {   String refctnewPhone;           
            if (refct.Phone__c != null)       
            {   refctnewPhone = Utilities.removeExtraChars(refct.Phone__c, '0123456789');    }
            if (refct.Name == ctctFullName)
            {   foundRefCt = refct;                 
                break;
            }   
            else if ((refct.Email__c == ctctEmail && refct.Last_Name__c == ctctLastName)
                        ||
                     (refct.Email__c == ctctEmail && refct.LastName__c == ctctLastName))                        
            {   foundRefCt = refct;              
                break;
            }   
            else if ((refctnewPhone == ctctSquishedPhone && refct.Last_Name__c == ctctLastName)
                        ||
                     (refctnewPhone == ctctSquishedPhone  && refct.LastName__c == ctctLastName)) 
            {   foundRefCt = refct;                 
                break;
            }   
        } // for searchRefCtctResults
                   
        return foundRefCt;
   } // searchRfrlCtct
        
} // class ReferralSearch