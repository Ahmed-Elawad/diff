/* Methods for handling merge activities

  History
  -------
  07/16/2019 Dan Carmen        Created
  08/25/2021 Dan Carmen        Replace the Referral Contact Create Merge Tracking and Referral Account Merge Request Tracking process builders
  
 */
public with sharing class MergeHelper implements TriggerInterfaceC {

   // for recursion
   public static Set<String> ALREADY_RAN_SET = new Set<String>();
    
   public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      SObjectType objType = recs[0].getSObjectType();
      String objTypeName = objType.getDescribe().getName();
      Boolean alreadyRan = ALREADY_RAN_SET.contains(objTypeName);
      System.debug('MergeHelper.triggerCheckAllFirst recs='+(recs != null ? recs.size() : -1)+' isAfter='+isAfter+' objTypeName='+objTypeName+' alreadyRan='+alreadyRan);
      if (alreadyRan || recs==null || recs.isEmpty()) {
         return;
      }
      if (isBefore) {
         if (objType == Contact.sObjectType) {
            checkBeforeActions(recs,oldMap,true,false);
         } else if (objType == Account.sObjectType) {
            checkBeforeActions(recs,oldMap,false,true);
         }
      } else if (isAfter) {
         ALREADY_RAN_SET.add(objTypeName);
         if (objType == Contact.sObjectType) {
            checkAfterActions(recs,oldMap,true,false,false,false);
         } else if (objType == Account.sObjectType) {
            checkAfterActions(recs,oldMap,false,true,false,false);
         } else if (objType == Referral_Contact__c.sObjectType) {
            checkAfterActions(recs,oldMap,false,false,true,false);
         } else if (objType == Referral_Account__c.sObjectType) {
            checkAfterActions(recs,oldMap,false,false,false,true);
         }
      }
   } // checkAllBeforeTrigger

   public static void checkBeforeActions(SObject[] recs, Map<Id,SObject> oldMap, Boolean isContact, Boolean isAccount) {
      User runningUser = UserHelper.getRunningUser();
      if (runningUser == null) {
         System.debug('checkBeforeActions could not find runningUser!');
         return;
      }
      for (SObject rec : recs) {
         SObject oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);
         String mergeName = (String)rec.get('Merge_Name__c');
         String oldMergeName = (oldRec != null ? (String)oldRec.get('Merge_Name__c') : null);
         Boolean toBeMerged = (Boolean)rec.get('To_Be_Merged_Merged__c');
         
         if (toBeMerged && (mergeName.containsIgnoreCase('primary1') || mergeName.containsIgnoreCase('sfdcapi1'))) {
            // When to be merged is selected on a Primary Merge record, clear out all Merge fields. This should happen on the survivor after the merge has completed.
            // workflows Clear Merge Field After Merge
            rec.put('Merge_Name__c',null);
            rec.put('Merge_Requestor_Email__c',null);
            rec.put('Merge_Request_Date__c',null);
            rec.put('To_Be_Merged_Merged__c',false);
         }
         if (String.isNotBlank(mergeName) && (oldRec == null || mergeName != oldMergeName)) {
            // if the merge name gets populated, enter submitter information
            // workflows ACCT: Merge Requested Date and 
            rec.put('Merge_Requestor_Email__c',runningUser.Email);
            rec.put('Merge_Request_Date__c',Date.today());
            if (!mergeName.containsIgnoreCase('primary1') && !mergeName.containsIgnoreCase('sfdcapi1')) {
               // when non-survivor has Merge Name populated, check the To Be Merged box
               // workflows To Be Merged Merged and Check To Be Merged
               rec.put('To_Be_Merged_Merged__c',true);
            }
         } else if (String.IsBlank(mergeName) && oldRec != null && String.isNotBlank(oldMergeName)) {
            // if the merge name field is cleared, then clear out related fields
            // workflows ACCT: Clear Merge Date Checkbox and CTCT: Clear Merge Date Checkbox
            rec.put('Merge_Requestor_Email__c',null);
            rec.put('Merge_Request_Date__c',null);
            rec.put('To_Be_Merged_Merged__c',false);
         }
         
      }
   } // checkBeforeActions
   
   // Replaces Process Builders: Contact: Create Merge Tracking and Account: Create Merge Tracking
   public static void checkAfterActions(SObject[] recs, Map<Id,SObject> oldMap, Boolean isContact, Boolean isAccount, Boolean isRefCtct, Boolean isRefAcct) {
      Merge_Request_Tracking__c[] newRequests = new Merge_Request_Tracking__c[]{};
      Id[] checkForContactMergeAcctIds = new Id[]{};
      for (SObject rec : recs) {
         SObject oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);
         String mergeName = (String)rec.get('Merge_Name__c');
         String oldMergeName = (oldRec != null ? (String)oldRec.get('Merge_Name__c') : null);
         System.debug('checkMergeName mergeName='+mergeName+' oldMergeName='+oldMergeName);
         if (String.isNotBlank(mergeName) && (oldRec == null || mergeName != oldMergeName)) {
            Merge_Request_Tracking__c mrt = new Merge_Request_Tracking__c();
            mrt.Date_Merge_Requested__c = Date.today();
            mrt.Merge_Name__c= mergeName;
            mrt.Merge_Requested_Type__c = (mergeName.containsIgnoreCase('Primary1') ? 'Survivor Record' : 'To be Merged');
            if (isContact) {
               Contact ctct = (Contact)rec;
               mrt.Contact__c = ctct.Id;
               mrt.Contact_Id__c = ctct.Id;
               mrt.Contact_Name__c = (ctct.FirstName+' '+ctct.LastName);
               mrt.Merge_Object__c = 'Contact';
            } else if (isAccount) {
               Account acct = (Account)rec;
               mrt.Account__c = acct.Id;
               mrt.Account_ID__c = acct.Id;
               mrt.Account_Name__c = acct.Name;
               mrt.Merge_Object__c = 'Account';
            } else if (isRefCtct) {
               Referral_Contact__c refCtct = (Referral_Contact__c)rec;
               mrt.Referral_Account__c = refCtct.Referral_Account__c;
               mrt.Referral_Contact__c = refCtct.Id;
               mrt.Referral_Contact_Id__c = refCtct.Id;
               mrt.Referral_Contact_Name__c = refCtct.Name;
               mrt.Merge_Object__c = 'Referral Contact';
            } else if (isRefAcct) {
               Referral_Account__c refAcct = (Referral_Account__c)rec;
               mrt.Referral_Account__c = refAcct.Id;
               mrt.Referral_Account_Id__c = refAcct.Id;
               mrt.Referral_Account_Name__c = refAcct.Name;
               mrt.Merge_Object__c = 'Referral Account';
            }
            newRequests.add(mrt);
         }
      } // for (SObject rec
      
      DmlHelper.performDML(newRequests, DmlHelper.DML_INSERT, 'MergeHelper', 'checkMergeName', 'Creating Merge Requests', true);
   } // checkAfterActions
   
} // class MergeHelper