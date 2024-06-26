/* Methods handled directly by the Contact before trigger
   
  History
  -------
  09/29/2016 Dan Carmen       Created
  04/18/2017 Cindy Freeman    Modified for SFDC data check for To Be Deleted reason
  02/19/2018 Cindy Freeman    Modified for Lead Loader check for To Be Deleted reason
  04/03/2018 Sunnish          uncheck Sales Contact if current user is not sales user only - put the code again on 05/11/2018 after it got replaced
  07/08/2019 Dan Carmen       If the Sales Contact is changed to true, make sure the Purge Exception and To Be Deleted Date fields are cleared
  04/09/2020 Dan Carmen       Remove logic for Relational Junction updating contacts
  07/28/2020 Michael Karcz	  Moved UserHelper.getRunningUser() check to first check for null
  04/17/2021 Dan Carmen       Increment API
  12/16/2022 Dan Carmen       Add process notes on insert of the contact for checking the sales contact flag.

 */
public with sharing class ContactTriggerBeforeMethods {

   public static Boolean setupDone = false;
   public static Boolean isSFDCuser = false;
   public static Boolean isLLuser = false;
   // the record type ids that we'll default the sales contact checkbox on
   public static Set<Id> salesContactRecordTypeIds = new Set<Id>();
   // the record type id we'll use when a contact is inserted by SFDC Data
   public static Id insertContactRtId = null;
   
   public static void checkSetup(Boolean isInsert) {
      if (Test.isRunningTest()) {
         setupDone = false;
         // make sure the custom settings are setup in the test environment.
         ZipCheckOwnerTest.setupCustomSettings();
      }
      if (!setupDone) {
         UserHelper.setRunningUserAttributes();
         isSFDCuser = UserHelper.runningUserIsSfdcData;
         isLLuser = UserHelper.runningUserIsLeadLoader;

         if (isInsert) {
            Map<String,Schema.RecordTypeInfo> rtMapByName = Contact.SObjectType.getDescribe().getRecordTypeInfosByName();
            Schema.RecordTypeInfo coreRt = rtMapByName.get(RecordTypeHelper.CORE_CONTACT);
            insertContactRtId = (coreRt != null ? coreRt.getRecordTypeId() : null);
            for (RecordType__c rtSetting : RecordType__c.getAll().values()) {
               if (rtSetting.DefaultSalesContact__c) {
                  RecordTypeInfo rtInfo = rtMapByName.get(rtSetting.Name);
                  if (rtInfo != null) {
                     salesContactRecordTypeIds.add(rtInfo.getRecordTypeId());
                     insertContactRtId = (insertContactRtId == null ? rtInfo.getRecordTypeId() : insertContactRtId);
                  }
               } // if (rtSetting.DefaultSalesContact__c
            } // for (RecordType__c rtSetting
         } // if (isInsert
         setupDone = true;
      } // if (!setupDone
   } // checkSetup

   public static void checkBeforeActions(Contact ctct, Contact oldCtct) {
      Boolean isInsert = (oldCtct == null);
      checkSetup(isInsert);
      
      // 8/5/2015 - turn off sales contact checkbox if not specific record types (duplicates what was previously done
      //            in a workflow - need to control order of operations).
      // the check for salesContactRecordTypeIds being empty is so that existing tests don't break.
      User runningUser = UserHelper.getRunningUser();
      String profileName = runningUser == null ? '' : runningUser.Profile.Name;
      if (isInsert) {
         if (isSFDCuser && insertContactRtId != null) {
            ctct.RecordTypeId = insertContactRtId;
         }
         Boolean rtIsSales=salesContactRecordTypeIds.contains(ctct.RecordTypeId);
         Boolean isSalesProf=Utilities.isSalesProf(profileName);
         String debugMsg = 'salesContactRecordTypeIds='+salesContactRecordTypeIds.size()+' ctct.RecordTypeId='+ ctct.RecordTypeId+' rtIsSales='+rtIsSales+' profileName='+profileName+' isSalesProf='+isSalesProf;
         StringHelper.addToProcessNotes(ctct,debugMsg);
         if (!Test.isRunningTest() && !salesContactRecordTypeIds.isEmpty() && ctct.RecordTypeId != null && !rtIsSales && !isSalesProf) {
            StringHelper.addToProcessNotes(ctct,'Setting Sales_Contact__c to false');
            ctct.Sales_Contact__c = false;
         }
                                                   
      }
      
      if (!isInsert && ctct.To_Be_Deleted__c != oldCtct.To_Be_Deleted__c)
      {     if ((isSFDCuser || isLLuser) && ctct.To_Be_Deleted__c && String.isBlank(ctct.Reason_for_Delete__c))
            {   ctct.Reason_for_Delete__c = 'HRIS-No longer used';  }
            if (!ctct.To_Be_Deleted__c && !String.isBlank(ctct.Reason_for_Delete__c))
            {   ctct.Reason_for_Delete__c = null;   }
      } // if (To_Be_Deleted__c...
      
      // if the sales contact checkbox changes to true, clear the To Be Deleted Date and Purge Exception
      if (oldCtct != null && ctct.Sales_Contact__c && !oldCtct.Sales_Contact__c
            && (ctct.To_Be_Deleted_Date__c != null || String.isNotBlank(ctct.Purge_Exception__c))) {
         ctct.To_Be_Deleted_Date__c = null;
         ctct.Purge_Exception__c = null;
      }
   } // checkBeforeActions

} // class ContactTriggerBeforeMethods