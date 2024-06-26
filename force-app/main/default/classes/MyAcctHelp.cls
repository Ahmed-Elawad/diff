/**
 * Get Referral Contact details for the current user in community.
 *
 * History
 * -------
 * 12/29/2022    Vinay       Created.
 */
public without sharing class MyAcctHelp {
  public String referralContactOwnerName { get; set; }
  public String phone { get; set; }
  public String email { get; set; }
  /**
   * Constructor
   */
  @TestVisible
  public MyAcctHelp() {
    Id userId = UserInfo.getUserId();
    Id contactId = [SELECT ContactId FROM User WHERE Id = :userId LIMIT 1]
    .ContactId;
    Contact contactOwner = [
      SELECT Id, Mirror_Ref_Ctct__r.OwnerId
      FROM Contact
      WHERE Id = :contactId
    ];
    User userData = [
      SELECT Id, Name, IsActive, Manager.Name, Phone, MobilePhone, Email
      FROM User
      WHERE Id = :contactOwner.Mirror_Ref_Ctct__r.OwnerId
    ];
    this.referralContactOwnerName = userData.IsActive
      ? userData.Name
      : userData.Manager.Name;
    this.phone = !String.isBlank(userData.MobilePhone)
      ? userData.MobilePhone
      : userData.Phone;
    this.email = userData.Email;
  }
}