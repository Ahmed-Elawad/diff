/* 

  History
  -------
  03/22/2022 Dan Carmen          Cleaned up code
  03/08/2022 Lalan Kumar         Optimize the query for contacts, single qurey in method getAllContactsForAccount and added new methods for DNC and EOO
  06/05/2023 Pujitha Madamanchi  APR0153007: Update Marketing Nurture logic
 */
public with sharing class ContactDA  {
public static List<Contact> allContactsForAccount = new List<Contact>();
    public List<Contact> getContactsByHRPersonId(List<string> hrPersonIds) {
        System.debug('getContactsByHRPersonId hrPersonIds='+hrPersonIds);
        Contact[] ctcts = 
            [
                SELECT Id
                FROM Contact
                WHERE HR_Person_Id__c IN :hrPersonIds
            ];
        return ctcts;
    }

    /*Below Method is to fetch all the Contacts of an Account -APR0133627*/ 
    public List<Contact> getAllContactsForAccount(Id accountId) {
      
        allContactsForAccount = [
            SELECT Id,
            Name,
            DoNotCall,
            HasOptedOutOfEmail,
            NSSOwnership__c,
            In_Marketing_Nurture__c,
            createddate
            FROM Contact
            WHERE Id IN (
                SELECT ContactId
                FROM AccountContactRelation
                WHERE AccountId = :accountId
            )
        ];
        system.debug('allContactsForAccount ++' + allContactsForAccount);
        return allContactsForAccount;
    }
    
    public List<Contact> getDoNotCallContactsForAccount(Id accountId) {
    List<Contact> contactsForAccount = new List<Contact>();
        system.debug('allContactsForAccount ++' + allContactsForAccount);
        for (Contact con: allContactsForAccount){
             if(con.DoNotCall!=null && con.DoNotCall){
                 contactsForAccount.add(con);
             }
        }
        return contactsForAccount;
    }

    public List<Contact> getEmailOptOutContactsForAccount(Id accountId) {
    List<Contact> contactsForAccount = new List<Contact>();
        system.debug('allContactsForAccount ++' + allContactsForAccount);
        for (Contact con: allContactsForAccount){
             if(con.HasOptedOutOfEmail!= null && con.HasOptedOutOfEmail){
                 contactsForAccount.add(con);
             }
        }
        return contactsForAccount;
    }
   
    public List<Contact> getMarketingOwnedContact(Id accountId) {
        List<Contact> contactsForAccount = new List<Contact>();
          Contact tempCont;
        system.debug('allContactsForAccount ++' + allContactsForAccount);
        for (Contact con: allContactsForAccount){
            //APR0153007: Update Marketing Nurture logic to check for In_Marketing_Nurture__c
           // if(con.NSSOwnership__c!= null && con.NSSOwnership__c.contains('Marketing') && (tempCont == null || tempCont.createddate < con.createddate)){
            if(con.In_Marketing_Nurture__c && (tempCont == null || tempCont.createddate < con.createddate)){
                 tempCont = con;
             }
        }
        contactsForAccount.add(tempCont);
        system.debug('contactsForAccount -->' + contactsForAccount);
        return contactsForAccount;
    }
} // class ContactDA