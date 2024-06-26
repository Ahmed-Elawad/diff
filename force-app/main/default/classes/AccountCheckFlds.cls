/* Check on the fields of the account

  History
  -------
  02/08/2017 Dan Carmen        Created
  06/14/2017 Dan Carmen        If Lead Loader, update the Employees__c field from NumberOfEmployees
  11/02/2018 Dan Carmen        Call the AcctSensitivityQueueable if a referral source changes
  12/27/2018 Dan Carmen        Change for queueable getting launched twice.
  02/12/2019 Dan Carmen        Add Insurance_Broker_Name_Ref__c
  10/15/2018 Lynn Michels      If SFDC Data, do not save employee count and create Account Field Tracking record.
  04/29/2019 Dan Carmen        Add field to remove process builders.
  06/24/2021 Dan Carmen        Log Main_Owner_Changed_Date__c if the owner id changes and the owner is a certain type.
  07/01/2021 Jake Hinds        Check if runningUser is null
  12/30/2022 Dan Carmen        Added check for address information
  
 */
public without sharing class AccountCheckFlds implements TriggerInterfaceC {
   
   public static Integer A1_HoldOutDays = Integer.valueOf(Label.RepType_A1_HoldOutDays);
    
   // if the account is any of these types and the owner changes, log the change date.
   public static String[] OWNER_CHANGE_TYPES=Label.Account_MainOwnerChangeType.split(',');

   public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      if (isBefore) {
         checkAllBeforeTrigger(recs,oldMap);
      } else if (isAfter) {
         checkReferralSourceChange((Account[])recs, (Map<Id,Account>)oldMap);
      }
   } // handleTrigger

   public void checkAllBeforeTrigger(SObject[] recs, Map<Id,Object> oldMap) {
      UserHelper.setRunningUserAttributes();
      User runningUser = UserHelper.getRunningUser();
      List<Account_Field_Tracking__c> aftList = new List<Account_Field_Tracking__c>();
      Map<Id, Account> checkLostSMBChannel = new Map<Id, Account>();
       
      for (SObject obj : recs) {
         Account acct = (Account)obj;
         Account oldAcct = (Account)(oldMap != null ? oldMap.get(acct.Id) : null);
         // because of the trigger on the number of employees field, we have to redirect the trigger to update the Employees__c field instead
         // if it's coming from LeadLoader
         if ((oldAcct == null && acct.Employees__c==null) || (UserHelper.runningUserIsLeadLoader && oldAcct != null && acct.NumberOfEmployees != oldAcct.NumberOfEmployees)) {
             acct.Employees__c = acct.NumberOfEmployees;
         }
         Boolean checkOwnerChange = (OWNER_CHANGE_TYPES.contains('All') || (String.isNotBlank(acct.Type) && OWNER_CHANGE_TYPES.contains(acct.Type)));
         if (checkOwnerChange && (oldAcct == null || acct.OwnerId != oldAcct.OwnerId)) {
            acct.Main_Owner_Changed_Date__c = Datetime.now();
         }
         if (String.isNotBlank(acct.AccountNumber) && acct.AccountNumber.contains('-') 
                  && (String.isBlank(acct.EnterpriseClientNumber__c) || (oldAcct != null && acct.AccountNumber != oldAcct.AccountNumber))) {
            String cltNbr = acct.AccountNumber.subString(acct.AccountNumber.indexOf('-')+1);
            acct.EnterpriseClientNumber__c = cltNbr;
         }
         // only on the insert of an account, if the rep is an A-1 rep, set a holdout
         if (oldAcct == null && runningUser!=null && runningUser.User_Type__c == Label.RepType_A1) {
            acct.Hold_Out__c = true;
            acct.Hold_Out_Expiration__c = Date.today().addDays(A1_HoldOutDays);
            acct.Permanent_Hold_Out_Description__c = Label.RepType_A1;
         }
         //LM Case # 29845143 If The feed tries to update the Employees__c field and the EE Count From Risk has a date, do not allow the update
          else if (UserHelper.runningUserIsSfdcData && oldAcct != null && (acct.Employees__c != oldAcct.Employees__c) && oldAcct.EE_Count_From_Risk__c != null) {
            //create a record to track the differences
             System.debug('AccountCheckFlds.checkAllBeforeTrigger create Account Field Tracking record');
             Account_Field_Tracking__c aftNew = new Account_Field_Tracking__c(Prospect_Client__c = acct.id,
                                                                      EE_Count_From_Feed__c = acct.Employees__c,
                                                                      EE_Count_From_Risk__c = oldAcct.Employees__c);
             aftList.add(aftNew); 
                                                                
             //do not let the feed update the field. set the field back to the value that was previously there
             acct.Employees__c = oldAcct.Employees__c;
          }//end else if
            
         // if the flag is set on an update
         if (oldAcct != null && acct.CheckSensitivityList__c) {
            refSrcChangedIdSet.add(acct.Id);
            acct.CheckSensitivityList__c = false;
         }
         
         // keep the 2 account SIC code fields in sync.
         // Replaces the Account Sync SIC Codes process builder
         Boolean sic1Changed = (String.isNotBlank(acct.Sic) && (oldAcct == null || acct.Sic != oldAcct.Sic));
         Boolean sic2Changed = (String.isNotBlank(acct.SIC_Code__c) && (oldAcct == null || acct.SIC_Code__c != oldAcct.SIC_Code__c));
         if (sic1Changed && (acct.Sic != acct.SIC_Code__c)) {
            acct.SIC_Code__c = acct.Sic;
         } else if (sic2Changed && acct.Sic != acct.SIC_Code__c) {
            acct.Sic = acct.SIC_Code__c;
         }
         
         // replace Account Profiled Checkbox and Date process builder
         if (acct.Profiled__c == false && (acct.Profiled_Date__c != null || acct.Profiled_Expiration_Date__c != null)) {
            acct.Profiled_Date__c = null;
            acct.Profiled_Expiration_Date__c = null;
         }
         
         // replace W2 Address Change TimeStamp
         if (String.isNotBlank(acct.W2_Delivery_Address__c) && (oldAcct == null || String.isBlank(oldAcct.W2_Delivery_Address__c))) {
            acct.W2_Delivery_Address_TimeStamp__c = Datetime.now();
         }
         
          //Check if the SMB Channel hold out needs to be set for this Lost Client
          System.debug('AccountCheckFlds Check if Account went Lost.');
          if(oldAcct != null && ((acct.Type != null && oldAcct.Type != null && acct.Type.contains('Lost') && acct.Type != oldAcct.Type) || (oldAcct.Lost_Date__c == null && acct.Lost_Date__c != null)) && !checkLostSMBChannel.containsKey(acct.Id))
          {
              System.debug('AccountCheckFlds Account went Lost.');
              checkLostSMBChannel.put(acct.Id, acct);
          }
      } // for (SObject obj : recs
       
       if(!checkLostSMBChannel.isEmpty())
       {
           checkSetHoldOut(checkLostSMBChannel);
       }
      
      if(!aftList.isEmpty()){
        DmlHelper.performDML2(aftList, DmlHelper.DML_INSERT, 'AccountCheckFlds', 'processBeforeTriggerActions', 'create new Account Field Tracking record', true);
      }
   } // checkAllBeforeTrigger

   public static Set<Id> refSrcChangedIdSet = new Set<Id>();
   
   // to prevent launching multiple times
   public static Boolean ALREADY_PROCESSED=false;
   
    
   public static void checkReferralSourceChange(Account[] accts, Map<Id,Account> oldMap) {
      if (ALREADY_PROCESSED) {
         return;
      }
      ALREADY_PROCESSED = true;
      Id[] acctIdsToProcess = new Id[]{};
      acctIdsToProcess.addAll(refSrcChangedIdSet);
      for (Account acct : accts) {
         if (acct.Id == null || !refSrcChangedIdSet.contains(acct.Id)) {
            Account oldAcct = (oldMap != null ? oldMap.get(acct.Id) : null);
            // if it's an insert and there's a value or if one of the referral sources changes
            if ((oldAcct == null && (acct.Banker_Name_Ref__c != null
                                    || acct.Broker_Name_Ref__c != null
                                    || acct.CPA_Name_Ref__c != null
                                    || acct.Insurance_Broker_Name_Ref__c != null
                                    || acct.Referral_National_Account__c != null))
                || (oldAcct != null && (acct.Banker_Name_Ref__c != oldAcct.Banker_Name_Ref__c
                                    || acct.Broker_Name_Ref__c != oldAcct.Broker_Name_Ref__c
                                    || acct.CPA_Name_Ref__c != oldAcct.CPA_Name_Ref__c
                                    || acct.Insurance_Broker_Name_Ref__c != oldAcct.Insurance_Broker_Name_Ref__c
                                    || acct.Referral_National_Account__c != oldAcct.Referral_National_Account__c))
                ) {
               acctIdsToProcess.add(acct.Id);
            } // if ((oldAcct == null
         } // if (acct.Id == null
      } // for (Account acct
      
      refSrcChangedIdSet.clear();
      if (!acctIdsToProcess.isEmpty()) {
         AcctSensitivityQueueable.checkLaunchQueueable(acctIdsToProcess);
         acctIdsToProcess.clear();
      }
   } // checkReferralSourceChange
    
    //Checks to see if the Payroll Lost Client SMB Channel Hold Out is needed.
    public static void checkSetHoldOut(Map<Id, Account> checkLostSMBChannel)
    {
        System.debug('AccountCheckFlds getting account for SMB Channel check.');
        List<Account> accts = [SELECT Id, Name, Type, Lost_Date__c, IsChild__c, NumberOfEmployees, 
                               OwnerId, Owner.Sales_Org__c, Owner.Sales_Division__c,
                               (SELECT Id, Name, Type, OpportunityType__c, OwnerId, StageName FROM Opportunities WHERE OpportunityType__c = 'Payroll' ORDER BY CreatedDate DESC LIMIT 1)
                               FROM Account WHERE Id IN :checkLostSMBChannel.keySet()];
        
        System.debug('AccountCheckFlds accts.size()='+accts.size());
        
        String[] smbOpptyStages = Label.SMBChannelOwnershipStatus.split(',');

        for (Account acct : accts)
        {
            ///System.debug('AccountCheckFlds acct.Owner.Sales_Division__c='+acct.Owner.Sales_Division__c+' acct.isChild__c='+acct.isChild__c+' acct.Opportunities.size()='+acct.Opportunities.size());
            if(acct != null && acct.Owner.Sales_Division__c != null && (acct.Owner.Sales_Division__c.contains('SMB') && acct.Owner.Sales_Division__c.contains('Channel')) && !acct.isChild__c && 
               acct.Opportunities.size() == 1 && acct.OwnerId == acct.Opportunities[0].OwnerId && 
               String.isNotBlank(acct.Opportunities[0].StageName) && smbOpptyStages.contains(acct.Opportunities[0].StageName))
            {
                System.debug('AccountCheckFlds setting SMB Channel Hold Out.');
                List<HoldOut_Dictionary__c> hoDictionary = HoldOut_Dictionary__c.getall().values();
                
                Map<String, HoldOut_Dictionary__c> hoMap = new Map<String, HoldOut_Dictionary__c>();
                for (HoldOut_Dictionary__c ho:hoDictionary) {
                    hoMap.put(ho.Name, ho);     
                }
                
                HoldOut_ExpirationDates__c hoDates = HoldOut_ExpirationDates__c.getInstance('PAY');
                if (hoDates == null) {
                    continue;
                }
                
                HoldOut_Dictionary__c hod = hoMap.get('Payroll Lost Client');
                if(hod != null && acct.NumberOfEmployees >= hod.Min_Employees__c && acct.NumberOfEmployees <= hod.Max_Employees__c)
                {
                    Account origAccount = checkLostSMBChannel.get(acct.Id);
                    if(origAccount != null)
                    {
                        origAccount.put(hoDates.Account_Hold_Out_Date__c, null);
                        origAccount.put(hoDates.Account_Hold_Out__c,true);
                        origAccount.put(hoDates.HoldOutReasonFld__c,hod.Name);
                        System.debug('AccountCheckFlds hoDates.HoldOutReasonFld__c='+hoDates.HoldOutReasonFld__c+' (hoDates.Account_Hold_Out__c='+hoDates.Account_Hold_Out__c+' hoDates.Account_Hold_Out_Date__c='+hoDates.Account_Hold_Out_Date__c);
                        System.debug('AccountCheckFlds origAccount.get(hoDates.HoldOutReasonFld__c)='+origAccount.get(hoDates.HoldOutReasonFld__c)+' origAccount.get(hoDates.Account_Hold_Out__c)='+origAccount.get(hoDates.Account_Hold_Out__c)+' origAccount.get(hoDates.Account_Hold_Out_Date__c)='+origAccount.get(hoDates.Account_Hold_Out_Date__c));
                    }

                }
            }
        }
    }

} // class AccountCheckFlds