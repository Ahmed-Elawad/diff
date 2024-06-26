/* 

  History
  -------
  03/22/2022 Dan Carmen          Cleaned up code
  03/08/2023 Lalan Kumar         Added getAllContactsForAccount
 */
public interface ContactDAInterface {
    List<Contact> getContactsByHRPersonId(List<String> hrPersonIds);
    List<Contact> getAllContactsForAccount(Id accountId);
    List<Contact> getDoNotCallContactsForAccount(Id accountId);
    List<Contact> getEmailOptOutContactsForAccount(Id accountId); 
    List<Contact> getMarketingOwnedContact(Id accountId);
}