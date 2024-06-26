/* Test methods for the AccountDeleteCheck class

  History
  -------
  01/10/2017 Dan Carmen        Created
  10/02/2023 Carrie Marciano   Removed code that tested deleted code in AccountDeleteCheck class, incremented API version
  
 */
@isTest
private class AccountDeleteCheckTest {

   static testMethod void checkDelete() {
      // create an account that can't be deleted 
      Account acct = new Account(Name='Test Acct', PartnerId__c='A123');
      insert acct;
      
      PartnerDetail__c partDetail = new PartnerDetail__c(Name='Test', Account__c=acct.Id, ReferralPaymentStart__c=Date.today().addDays(-10));
      insert partDetail;
      
      acct.PartnerDetail__c = partDetail.Id;
      update acct;
      
      try {
         delete acct;
         // should not get here
         System.assertEquals(true,false);
      } catch (Exception e) {
         System.debug('checkDelete e='+e);
         System.assertEquals(true,true);
      }
      
   } // checkDelete
   
   static testMethod void checkDeleteSysAdmin() {
      // create an account that can't be deleted 
      Id acctRT = RecordTypeHelper.getRecordType('System Administration Account', 'Account').getRecordTypeId();
      Account payx = new Account(Name='Paychex Inc SA',RecordTypeId=acctRT);
      insert payx;
      
      try {
         delete payx;
         // should not get here
         System.assertEquals(true,false);
      } catch (Exception e) {
         System.debug('checkDelete e='+e);
         System.assertEquals(true,true);
      }
      
   } // checkDeleteSysAdmin
    
   static testMethod void checkDeleteWithParent() {
      Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_REFERRAL_ACCOUNT, 'Account');
      Account parent = new Account(Name='Parent Acct', PartnerId__c='DAN1', RecordTypeId=rtAcct.getRecordTypeId());
      insert parent;
      
      PartnerDetail__c partDetail = new PartnerDetail__c(Name='Test', Account__c=parent.Id, ReferralPaymentStart__c=Date.today().addDays(-10), ReferralPaymentEnd__c=Date.today().addDays(10));
      insert partDetail;
      
      Account child = new Account(Name='Child Acct', ReferralParent__c=parent.Id, RecordTypeId=rtAcct.getRecordTypeId());
      insert child;
      
      try {
         delete child;
         // should not get here
         System.assertEquals(true,false);
      } catch (Exception e) {
         System.debug('checkDelete e='+e);
         System.assertEquals(true,true);
      }
      
   } // checkDeleteWithParent
   
} // class AccountDeleteCheckTest