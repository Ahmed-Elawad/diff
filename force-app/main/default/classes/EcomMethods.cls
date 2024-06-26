/* 
   Methods for working with the ECommerce__c object

   
  History
  -------
  10/06/2020 Dan Carmen        Created
  06/29/2021 Dan Carmen        Change to set account owner/hold out on lead convert
  08/10/2021 Dan Carmen        Remove the call to launch the batch job
  03/10/2022 Jaipal            Added Createleadfromecom method to get the form 1 from ECommerce directly to SF insteaf of Marketo team and create lead
  07/26/2022 Dan Carmen        Handle Account updates from CSO
  08/15/2022 Dan Carmen        Fix for setting Branch-Client Number
  08/18/2022 Dan Carmen        Add First Payroll Run Date
  10/05/2022 Dan Carmen        Fix to select the latest tracker
  10/26/2022 Dan Carmen        Add process start/end
  11/14/2022 Dan Carmen        Add updates/inserts from Enterprise
  01/25/2023 Dan Carmen        Check if the integer is null before updating (so don't update null)
  04/10/2023 Dan Carmen        Ability to change opp record type based on an incoming Action
  05/23/2023 Dan Carmen        Don't change the opp record type in checkOppRecordType if currently ecom.
  09/19/2023 Dan Carmen        Fix check interval when creating an account from the Client Legal message.
  10/19/2023 Dan Carmen        Change to be able to block the company name update from enterprise
  11/06/2023 Dan Carmen        Stop updating the ecoms after the partner referral is updated.
  01/17/2024 Dan Carmen        Ability to mark an ecom to not process and be purged
  03/07/2024 Dan Carmen        Add a label for the partner referral source field
  03/17/2024 Pujitha Madamanchi Populate Original EE count. 
  03/27/2024 Jaipal            Created a new field PriorWages__c and setting the field onto CSO Tracking Object(handleEcomRecord)
  04/01/2024 Dan Carmen        Fix for purge flag.
  04/12/2024 Dan Carmen        Purge selecting too many records.

*/

public without sharing class EcomMethods {
   
   public static final String CLASSNAME='EcomMethods';
   public static String LEAD_RT_NAME='Ecommerce Lead';
   public static String ACTION_OCC1='OCC Form 1';
   public static String ACTION_OCC2='OCC Form 2';
   public static String ACTION_OCC3='OCC Form 3';
   public static String ACTION_OCC4='OCC Form 4';
   public static String ACTION_FLEX1='Flex Login Completed';
   public static String ACTION_FLEX2='Onboarding Completed';
   public static String ACTION_CLT_UPDATE='Client Legal';
   //public static String ACTION_CLT_NEW='Enterprise New Client';
   
   // these are the actions where we're moving forward with the records
   //public static String[] ACTIONS_TO_PROCESS = new String[]{ACTION_OCC1,ACTION_OCC2,ACTION_OCC3,ACTION_OCC4,ACTION_FLEX1,ACTION_FLEX2};
   //public static String[] FLEX_ACTIONS = new String[]{ACTION_FLEX1,ACTION_FLEX2};
   public static String ECOMMERCE='Ecommerce';
   //public static String ACTION_ABANDON1='Form 1 - Abandoned';
   //public static String ACTION_ABANDON2='Form 2 - Abandoned';
   //public static String ACTION_ABANDON3='Form 3 - Abandoned';
   //public static String ACTION_ABANDON4='Form 4 - Abandoned';
   // these are the actions where the records are abandoned
   //public static String[] ACTIONS_ABANDONED = new String[]{ACTION_ABANDON1,ACTION_ABANDON2,ACTION_ABANDON3,ACTION_ABANDON4};
   public static Boolean UseCheckForPayroll=(Label.EcomMethods_UseCheckForPayroll == 'Yes');
    
   public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      System.debug('EcomMethods.handleTrigger recs='+recs.size()+' isBefore='+isBefore+' isAfter='+isAfter);
      if (TriggerMethods.SKIP_TRIGGERS) {
         return;
      }
      Ecommerce__c[] checkRecs = (Ecommerce__c[])recs;
      Map<Id,Ecommerce__c> triggeroldMap = (Map<Id,Ecommerce__c>)oldMap;
      if (isBefore) {
         for (Ecommerce__c ecom : checkRecs) {
            if (!ecom.Processed__c) {
                 
               Ecommerce__c oldEcom = (oldMap != null ? (Ecommerce__c)oldMap.get(ecom.Id) : null);
               if(String.isNotBlank(ecom.OracleCommerceCloudId__c) && String.isBlank(ecom.MktgId__c) ){
                   ecom.MktgId__c = ecom.OracleCommerceCloudId__c;
               }
               // only check for purge on insert
               if (oldEcom == null) {
                  checkForTest(ecom);
               }
               // if the record hasn't already been processed, set these fields so it will process.
               if (!ecom.PurgeRecord__c && !ecom.Processed__c && ecom.CheckCount__c == null && ecom.CheckTime__c == null) {
                   ecom.CheckCount__c = 0;
                   ecom.CheckTime__c = Datetime.now();
               }
               // not sure if we need this. This is just in case to have both dates populated during the transition
               if (UseCheckForPayroll && ecom.FirstCheckDate__c != null && ecom.FirstPayrollRunDate__c == null) {
                  ecom.FirstPayrollRunDate__c = ecom.FirstCheckDate__c;
               }
               if (String.isNotBlank(ecom.FEIN__c) && ecom.FEIN__c.length() == 9) {
                  ecom.FEIN__c = ecom.FEIN__c.left(2)+'-'+ecom.FEIN__c.right(7);
               }
            } // if (!ecom.Processed__c
         } // for (Ecommerce__c ecom
      } // if (isBefore
      if (isAfter) {
         checkRecsForPurge(checkRecs);
      } // if (isAfter
   } // handleTrigger
    
   public static void checkRecsForPurge(Ecommerce__c[] ecoms) {
      String[] actions = new String[]{};
      String[] purgeKeys = new String[]{};
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(EcomBatch.CLASSNAME);
      Integer maxAttempts = (abc.NbrOfAttempts__c != null ? Integer.valueOf(abc.NbrOfAttempts__c) : 2);

      for (Ecommerce__c ecom : ecoms) {
         if (String.isNotBlank(ecom.Action__c) && (String.isNotBlank(ecom.OracleCommerceCloudId__c) 
                                                    || String.isNotBlank(ecom.CAID__c))
             && (ecom.Processed__c || (!ecom.Processed__c && ecom.CheckCount__c >= maxAttempts))
             && (keepOnlyLatestActions.contains(ecom.Action__c) || keepFirstLastActions.contains(ecom.Action__c))) {
            actions.add(ecom.Action__c);
            if (String.isNotBlank(ecom.OracleCommerceCloudId__c)) {
               purgeKeys.add(ecom.OracleCommerceCloudId__c);
            }
            if (String.isNotBlank(ecom.CAID__c)) {
               purgeKeys.add(ecom.CAID__c);
            }
         }
      } // for (Ecommerce__c ecom : checkRecs
      System.debug('checkRecsForPurge purgeKeys='+purgeKeys.size());
      if (!purgeKeys.isEmpty()) {
         checkToPurge(actions, purgeKeys);
      }

   } // checkRecsForPurge
   
  public static String[] keepOnlyLatestActions = Label.EcomMethods_ActionsKeepLatest.split(',');
  public static String[] keepFirstLastActions = Label.EcomMethods_ActionsKeepFirstLast.split(',');
  public static Integer purgeLimit = Integer.valueOf(Label.EcomMethods_PurgeLimit);
   
  public static void checkToPurge(String[] actions, String[] purgeKeys) {
     System.debug('checkToPurge actions='+actions+' purgeKeys='+purgeKeys);
     Map<Id,Ecommerce__c> updateMap = new Map<Id,Ecommerce__c>();
     // if we store the first and last - this is the first one
     Map<String,Ecommerce__c> firstMap = new Map<String,Ecommerce__c>();
     // if we store the first and last - this is the last one, or for the latest only, the latest will be here
     Map<String,Ecommerce__c> lastMap = new Map<String,Ecommerce__c>();
      
     Ecommerce__c[] ecoms = [Select Id, Action__c, OracleCommerceCloudId__c, CAID__c, PurgeRecord__c, PurgeDate__c
                               From Ecommerce__c
                              Where PurgeRecord__c=false
                                and Action__c in :actions
                                and (OracleCommerceCloudId__c in :purgeKeys or CAID__c in :purgeKeys)
                              order by CreatedDate asc limit :purgeLimit];
     if (ecoms.size() >= purgeLimit) {
        return;
     }
     for (Ecommerce__c ecom : ecoms) {
        String key = (String.isNotBlank(ecom.OracleCommerceCloudId__c) ? ecom.OracleCommerceCloudId__c : ecom.CAID__c);
        key = (String.isNotBlank(key) ? key+ecom.Action__c : null);
        if (key != null && keepFirstLastActions.contains(ecom.Action__c) && !firstMap.containsKey(key)) {
           firstMap.put(key,ecom );
        } else if (key != null) {
           // if one's already in the map, then we now have one that's later, so we'll replace it.
           Ecommerce__c existingEcom = lastMap.get(key);
           if (existingEcom != null) {
              existingEcom.PurgeDate__c = Date.today();
              existingEcom.PurgeRecord__c = true;
              updateMap.put(existingEcom.Id, existingEcom);
           }
           lastMap.put(key,ecom);
        }
     } // for (Ecommerce__c ecom : ecoms
     if (!updateMap.isEmpty()) {
        TriggerMethods.SKIP_TRIGGERS=true;
        DmlHelper.performDML2(updateMap.values(), DmlHelper.DML_UPDATE, 'EcomMethods', 'checkToPurge', 'Update ecommerce records to purge', true);
     }
  } // checkToPurge
   
  public static String[] testFlds = Label.EcomMethods_TestFlds.split(',');
  public static String[] testValues = Label.EcomMethods_TestValues.split(',');
  // check if one of the test fields contains one of the test values. Do not further process those records and mark for purge.
  public static void checkForTest(Ecommerce__c ecom) {
     for (String fldName : testFlds) {
        try {
           String fldValue = String.valueOf(ecom.get(fldName));     
           if (String.isNotBlank(fldValue)) {
              for (String testVal : testValues) {
                 if (fldValue.contains(testVal)) {
                    ecom.PurgeRecord__c = true;
                    ecom.PurgeDate__c = Date.today();
                    ecom.CheckTime__c = null;
                    break;
                 }
              } // for (String testVal
           } // if (String.isNotBlank
        } catch (Exception e) {
           System.debug('checkForTest e='+e);
        }
     }
  } // checkForTest
   
   public static User ecomUser = null;
    
   public static User getEcomUser() {
      if (ecomUser == null) {
         ecomUser = (User)CacheManager.getOrg('EcomMethodsEcomUser');
      }
      if (ecomUser == null) {
         ecomUser = UserHelper.getRunningUser();
         if (ecomUser == null || ecomUser.LastName != 'Ecommerce') {
            try {
               ecomUser = [Select Id, Name, LastName, Email from User where IsActive=true and LastName='Ecommerce' limit 1];
            } catch (Exception e) {}
         }
         if (ecomUser != null) {
            CacheManager.putOrg('EcomMethodsEcomUser',ecomUser); 
         }
      } // if (ecomUser == null
      return ecomUser;
   } // getEcomUser

   public static String CACHE_ECOM_QUERY='EcomMethodsGetEcomQuery';
   public static String getEcomQuery() {
      String query = (String)CacheManager.getOrg(CACHE_ECOM_QUERY);
      if (query == null) {
         Set<String> fldSet = new Set<String>();
         fldSet.add('CreatedDate');
         fldSet.add('EnterpriseUpdate__c');
         ObjectHelper.getSOQLQuery('ECommerce__c', null, true, false, false, false, true);
         if (ObjectHelper.latestSoqlWrapper != null) {
            fldSet.addAll(ObjectHelper.latestSoqlWrapper.flds);
         }
         query = DmlHelper.buildQueryFromSet(fldSet, 'ECommerce__c');
         CacheManager.putOrg(CACHE_ECOM_QUERY, query);
      } // if (query == null

      return query;
   } // getEcomQuery

    
   public static Ecommerce__c[] getEcoms(Id[] p_ecomIds, String[] p_mktgIds) {
      // in case a null value was passed in
      Id[] ecomIds = (p_ecomIds != null ? p_ecomIds : new Id[]{});
      String[] mktgIds = (p_mktgIds != null ? p_mktgIds : new String[]{});
      System.debug('getEcoms ecomIds'+ecomIds);
      System.debug('getEcoms mktgIds'+mktgIds); 
      String query = getEcomQuery();
      query += ' Where Id in :ecomIds or mktgid__c in :mktgIds order by SortOrder__c ASC, CreatedDate ASC ';
      ECommerce__c[] ecoms = Database.query(query);

      System.debug('getEcoms ecomIds='+ecomIds.size()+' mktgIds='+mktgIds.size()+' ecoms='+ecoms.size());
      return ecoms;
   } // getEcoms

   public static String[] partRefSources = Label.EcomMethods_PartRefSource.split(',');
   public static PartnerReferral__c[] getPartRefs(Id[] p_partRefIds, String[] p_otherids) {
      Id[] partRefIds = (p_partRefIds != null ? p_partRefIds : new Id[]{});
      String[] otherIds = (p_otherids != null ? p_otherids : new String[]{});
      PartnerReferral__c[] partRefs = [Select Id
                                             ,Account__c
                                             ,Account__r.Id
                                             ,Account__r.OwnerId
                                             ,Account__r.Hold_Out__c
                                             ,Account__r.Hold_Out_Expiration__c
                                             ,Account__r.Permanent_Hold_Out_Description__c
                                             ,Account__r.EcommerceProductSold__c
                                             ,Account__r.Name
                                             ,Account__r.AccountNumber
                                             ,Account__r.DBA__c
                                             ,Account__r.EnterpriseClientNumber__c
                                             ,Account__r.Federal_ID_Number__c
                                             ,Account__r.First_Run_Date__c
                                             ,Account__r.Frequency__c
                                             ,Account__r.Paychex_CAID__c
                                             ,Account__r.Paychex_CEID__c
                                             ,Account__r.BillingStreet
                                             ,Account__r.BillingCity
                                             ,Account__r.BillingState
                                             ,Account__r.BillingPostalCode
                                             ,Account__r.BillingCountry
                                             ,Account__r.ShippingStreet
                                             ,Account__r.ShippingCity
                                             ,Account__r.ShippingState
                                             ,Account__r.ShippingPostalCode
                                             ,Account__r.ShippingCountry
                                             ,Account__r.Employees__c
                                             ,Account__r.NumberOfEmployees
                                             ,Account__r.Industry
                                             ,Account__r.ProcessNotes__c
                                             ,Campaign__c
                                             ,Campaign__r.LeadSource__c
                                             ,CampaignId__c
                                             ,CAID__c
                                             ,CEID__c
                                             ,City__c
                                             ,ClientNbr__c
                                             ,Company__c
                                             ,Contact__c
                                             ,Contact__r.Id
                                             ,Contact__r.OwnerId
                                             ,Contact__r.Name
                                             ,Contact__r.LeadSource
                                             ,Contact__r.FirstName
                                             ,Contact__r.LastName
                                             ,Contact__r.Email
                                             ,Contact__r.Phone
                                             ,Contact__r.Title
                                             ,Contact__r.Contact_Stage__c
                                             ,Contact__r.Hold_Out__c
                                             ,Contact__r.Hold_Out_Reason__c
                                             ,Contact__r.Hold_Out_Expiration__c
                                             ,Contact__r.FlexUEID__c
                                             ,Contact__r.MktgId__c
                                             ,Contact__r.User_Name__c
                                             ,Contact__r.UsernameDate__c
                                             ,EcomAncillaryBody__c
                                             ,EcomAncillaryEmail1__c
                                             ,EcomAncillaryEmail2__c
                                             ,Email__c
                                             ,FEIN__c
                                             ,FirstName__c
                                             ,LastName__c
                                             ,LatestEcommerce__c
                                             ,LatestEcommerce__r.Id
                                             ,LatestEcommerce__r.AbandonedAction__c
                                             ,LatestEcommerce__r.Action__c
                                             ,LatestEcommerce__r.SortOrder__c
                                             ,Lead__c
                                             ,Lead__r.Id
                                             ,Lead__r.OwnerId
                                             ,Lead__r.IsConverted
                                             ,Lead__r.ConvertedAccountId
                                             ,Lead__r.ConvertedContactId
                                             ,Lead__r.RecordTypeId
                                             ,Lead__r.RecordType.Name
                                             ,Lead__r.Lead_Company__r.AccountId__c
                                             ,Lead__r.Hold_Out__c
                                             ,Lead__r.Hold_Out_Reason__c
                                             ,Lead__r.Hold_Out_Expiration__c
                                             ,Lead__r.FirstName
                                             ,Lead__r.LastName
                                             ,Lead__r.LeadSource
                                             ,Lead__r.Email
                                             ,Lead__r.Phone
                                             ,Lead__r.Title
                                             ,Lead__r.Company
                                             ,Lead__r.Street
                                             ,Lead__r.City
                                             ,Lead__r.State
                                             ,Lead__r.PostalCode
                                             ,Lead__r.Country
                                             ,Lead__r.DBA__c
                                             ,Lead__r.Federal_ID_Number__c
                                             ,Lead__r.Lead_Stage__c
                                             ,Lead__r.Paychex_CAID__c
                                             ,Lead__r.Paychex_CEID__c
                                             ,Lead__r.Industry
                                             ,Lead__r.NumberOfEmployees
                                             ,Lead__r.Frequency__c
                                             ,Lead__r.ProcessNotes__c
                                             ,LeadSource__c
                                             ,MarketingStageCurrent__c
                                             ,MktgId__c
                                             ,NumberOfEmployees__c
                                             ,Opportunity__c
                                             ,Phone__c
                                             ,ProcessNotes__c
                                             ,Referral__c
                                             ,Referral__r.Id
                                             ,Referral__r.Account__c
                                             ,Referral__r.OwnerId
                                             ,Referral__r.Owner.Email
                                             ,Referral__r.ProductReferred__c
                                             ,Referral__r.ReferralJoin__c
                                             ,Referral__r.ReferralJoin__r.Id
                                             ,Referral__r.Referral_Partner__c
                                             ,Referral__r.Referral_Partner__r.Id
                                             ,Referral__r.Referral_Partner__r.Name
                                             ,Referral__r.Referral_Partner__r.Partner_Type__c
                                             ,Referral__r.Referral_Partner__r.Sales_Org__c
                                             ,Referral__r.Referral_Partner__r.NSS_Source__c
                                             ,Referral__r.Referral_Partner__r.SellingOpportunityType__c
                                             ,Referral__r.SourceContact__c
                                             ,Referral__r.SourceLead__c
                                             ,Referral__r.Selling_Opportunity__c
                                             ,Referral__r.Selling_Opportunity__r.Id
                                             ,Referral__r.Selling_Opportunity__r.Name
                                             ,Referral__r.Selling_Opportunity__r.OwnerId
                                             ,Referral__r.Selling_Opportunity__r.Check_Date__c
                                             ,Referral__r.Selling_Opportunity__r.CloseDate
                                             ,Referral__r.Selling_Opportunity__r.Frequency__c
                                             ,Referral__r.Selling_Opportunity__r.LeadSource
                                             ,Referral__r.Selling_Opportunity__r.NSS_Source__c
                                            // ,Referral__r.Selling_Opportunity__r.Probability
                                             ,Referral__r.Selling_Opportunity__r.Reason_Not_Sold__c
                                             ,Referral__r.Selling_Opportunity__r.Reason_Not_Sold_Details__c
                                             ,Referral__r.Selling_Opportunity__r.StageName
                                             ,Referral__r.Selling_Opportunity__r.Employees_Paid_Per_Payroll__c
                                             ,Referral__r.Selling_Opportunity__r.OpportunityType__c
                                             ,Referral__r.Selling_Opportunity__r.Payroll_Platform__c
                                             ,Referral__r.Selling_Opportunity__r.Non_Payroll_Units__c
                                             ,Referral__r.Selling_Opportunity__r.Payroll_Units__c
                                             ,Referral__r.Selling_Opportunity__r.RecordTypeId
                                             ,Source__c
                                             ,State__c
                                             ,StreetAddress__c
                                             ,Workable__c
                                             ,ZipPostalCode__c
                                         From PartnerReferral__c
                                        Where (Id in :partRefIds
                                           or MktgId__c in :otherIds
                                           or CAID__c in :otherIds
                                           or CEID__c in :otherIds)
                                          and MktgId__c != null
                                          //and Master_Partner_Referral__c = null
                                          and Source__c in :partRefSources
                                       order by CreatedDate desc];
                     
      return partRefs;
   } // getPartRefs
    
   public static void processEcoms(Id[] ecomIds) {
      Ecommerce__c[] ecoms = getEcoms(ecomIds, new String[]{});
      System.debug('processEcoms ecomIds='+ecomIds.size()+' ecoms='+ecoms.size());
      processEcoms(ecoms);
   } // processEcoms

   public static void createleadFromEcom(list<Ecommerce__c> form1Ecoms){
       system.debug('createleadFromEcom form1Ecoms='+form1Ecoms.size());
       list<lead>Insertlead=new list<Lead>();
       for(Ecommerce__c ec:form1Ecoms){
           Lead le = new Lead();
           le.Client_Referral__c=ec.Account__c ;
           le.Company=ec.Company__c ;
           le.FirstName=ec.ContactFirstName__c ;
           le.LastName=ec.ContactLastName__c ;
           le.PostalCode=ec.PostalCode__c ;
           le.email=ec.ContactEmail__c ;
           le.OwnedBy__c = 'eCommerce';
          // le.MktgId__c = ec.MktgId__c;
           le.MktgId__c = ec.OracleCommerceCloudId__c;
           le.Lead_Stage__c='MQL';
           if (String.isNotBlank(ec.CAMPAIGNID__c)) {
              try {
                 Id campId = (Id)ec.CAMPAIGNID__c;
                 le.LatestCampaign__c = campId;
              } catch (Exception e) {
                 StringHelper.addToProcessNotes(ec,'Unable to use '+ec.CAMPAIGNID__c+' for the CampaignId');
              }
           }
           ec.Lead__r=le;
           Insertlead.add(le);
       } //for(Ecommerce__c ec
       if(!Insertlead.IsEmpty()){
           DmlHelper.performDML2(Insertlead, DmlHelper.DML_INSERT, 'EcomMethods', 'createleadFromEcom', 'Inserting new Lead Related to Ecommerce', true);
       }
       for(Ecommerce__c ec:form1Ecoms){
          if (ec.Lead__r != null) {
             ec.Lead__c = ec.Lead__r.Id;
          }
       }
       
       
   } //createleadFromEcom

   public static void processEcoms(Ecommerce__c[] ecoms) {

      // collect the marketing ids and/or ceid/caid ids
      String[] otherIds = new String[]{};
      Ecommerce__c[] form1Ecoms = new Ecommerce__c[]{};
      Map<String,Ecommerce__c[]> csoMap = new Map<String,Ecommerce__c[]>();
      String[] caids = new String[]{};
      String[] cltNbrs = new String[]{};
          
      for (Ecommerce__c ecom : ecoms) {
         ecom.ProcessStart__c=Datetime.now();
         if (String.isNotBlank(ecom.CAID__c) && (String.isNotBlank(ecom.CSOTrackingFirst__c) 
                                                  || String.isNotBlank(ecom.CSOTrackingLatest__c) || String.isNotBlank(ecom.PriorWages__c))) {
             Ecommerce__c[] csoEcoms = (csoMap.containsKey(ecom.CAID__c) ? csoMap.get(ecom.CAID__c) : new Ecommerce__c[]{});
             csoEcoms.add(ecom);
             csoMap.put(ecom.CAID__c,csoEcoms);
         }
         // always update the ecom record
         ecomUpdateMap.put(ecom.Id, ecom);
         if (String.isNotBlank(ecom.OracleCommerceCloudId__c) && ecom.Action__c== ACTION_OCC1) {
             form1Ecoms.add(ecom);
         }
         if (String.isNotBlank(ecom.MktgId__c)) {
            otherIds.add(ecom.MktgId__c);
         }
         if (String.isNotBlank(ecom.ClientNbr__c)) {
            cltNbrs.add(ecom.ClientNbr__c);
         }

         if (String.isNotBlank(ecom.CAID__c)) {
            if (!ecom.EnterpriseUpdate__c) {
               otherIds.add(ecom.CAID__c);
            }
            caids.add(ecom.CAID__c);
         }
         //if (String.isNotBlank(ecom.CEID__c)) {
         //   otherIds.add(ecom.CEID__c);
         //}
      }
      
      System.debug('processEcoms otherIds='+otherIds.size()+' csoMap='+csoMap.size()+' form1Ecoms='+form1Ecoms.size()+' caids='+caids.size());
      //if (!csoMap.isEmpty()) {
      //   checkCSOTrackers(csoMap);
      //}
      // these need to be created here so the partner referral that's created is selected next.
      if (!form1Ecoms.IsEmpty()){
         createleadFromEcom(form1Ecoms);
      }
       
      PartnerReferral__c[] partRefs = (!otherIds.isEmpty() ? getPartRefs(new Id[]{}, otherIds) : new PartnerReferral__c[]{});
      // group into a map for easy reference
      Map<String,PartnerReferral__c> partRefMap = new Map<String,PartnerReferral__c>();
      System.debug('partRefs >>'+partRefs.size());
      Id[] acctIds = new Id[]{};
      for (PartnerReferral__c partRef : partRefs) {
         if (partRef.Account__c != null) {
            acctIds.add(partRef.Account__c);
         }
         // only take the first record of each id type
         System.debug('processEcoms partRef.Lead__c='+partRef.Lead__c);
         if (String.isNotBlank(partRef.MktgId__c) && !partRefMap.containsKey(partRef.MktgId__c)) {
            partRefMap.put(partRef.MktgId__c,partRef);
         }
         if (String.isNotBlank(partRef.CAID__c) && !partRefMap.containsKey(partRef.CAID__c)) {
            partRefMap.put(partRef.CAID__c,partRef);
         }
         //if (String.isNotBlank(partRef.CEID__c) && !partRefMap.containsKey(partRef.CEID__c)) {
         //   partRefMap.put(partRef.CEID__c,partRef);
         //}
      } // for (PartnerReferral__c partRef
       
      Map<String,CSO_Tracking__c> csoTrackMap = getCSOTrackerMap(csoMap);
      // see if there are more account ids
      for (CSO_Tracking__c tracker : csoTrackMap.values()) {
          if (tracker.AccountId__c != null) {
             acctIds.add(tracker.AccountId__c);
          }
      } // for (CSO_Tracking__c tracker : csoTrackMap.values
       
      Map<String,Account> acctMap = getAcctMap(acctIds, caids, cltNbrs);

      System.debug('processEcoms ecoms='+ecoms.size()+' partRefs='+partRefs.size()+' partRefMap='+partRefMap.size()+' csoTrackMap='+csoTrackMap.size()+' acctMap='+acctMap.size());
      
      EcomWrap[] wraps = new EcomWrap[]{};
      for (Ecommerce__c ecom : ecoms) {
         PartnerReferral__c partRef = (String.isNotBlank(ecom.MktgId__c) ? partRefMap.get(ecom.MktgId__c) : null);
         if (partRef == null && String.isNotBlank(ecom.CAID__c) && partRefMap.containsKey(ecom.CAID__c)) {
            partRef = partRefMap.get(ecom.CAID__c);
         }
         //if (partRef == null && String.isNotBlank(ecom.CEID__c) && partRefMap.containsKey(ecom.CEID__c)) {
         //   partRef = partRefMap.get(ecom.CEID__c);
         //}
         CSO_Tracking__c csoTracker = (String.isNotBlank(ecom.CAID__c) ? csoTrackMap.get(ecom.CAID__c) : null);
         Account acct = ((String.isNotBlank(ecom.CAID__c) && acctMap.containsKey(ecom.CAID__c)) ? acctMap.get(ecom.CAID__c)
                            : ((partRef != null && partRef.Account__c != null) ? acctMap.get(partRef.Account__c) 
                               : (csoTracker != null && csoTracker.AccountId__c != null ? acctMap.get(csoTracker.AccountId__c) 
                                  : (ecom != null && String.isNotBlank(ecom.ClientNbr__c) ? acctMap.get(ecom.ClientNbr__c) : null))));
         StringHelper.addToProcessNotes(ecom,'hasPartRef='+(partRef != null)+' csoTracker='+(csoTracker != null)+' acct='+(acct != null)+' EnterpriseUpdate__c='+ecom.EnterpriseUpdate__c);
         if (partRef != null || csoTracker != null || ecom.EnterpriseUpdate__c) {
            wraps.add(handleEcom(ecom,partRef,csoTracker,acct));
            if (ecom.Processed__c) {
               // clear this out if handled.
               ecom.CheckTime__c = null;
               ecom.ProcessEnd__c = Datetime.now();
            }
           System.debug('processEcoms 2 partRef.Lead__c='+(partRef != null ? partRef.Lead__c : null));
         } else {
            ecomUpdateMap.put(ecom.Id,ecom);
            StringHelper.addToProcessNotes(ecom,'Unable to find Partner Referral or CSO Tracker');
         }
      } // for (Ecommerce__c ecom : ecoms
      checkSaveAncillaries(wraps);
      checkSaveRecs(wraps);

   } // processEcoms
   
   public static final String CACHE_CSO_QUERY='EcomMethodsCSOTrackerQuery';
   
   public static String getCSOTrackerQuery() {
      String query = (String)CacheManager.getOrg(CACHE_CSO_QUERY);
      if (query == null) {
         Set<String> fldSet = new Set<String>();
         ObjectHelper.getSOQLQuery('CSO_Tracking__c', null, true, false, false, false, true);
         if (ObjectHelper.latestSoqlWrapper != null) {
            fldSet.addAll(ObjectHelper.latestSoqlWrapper.flds);
         }
         fldSet.add('LatestAction__r.SortOrder__c');
         DmlHelper.addFieldsToSet(Schema.SObjectType.Account.fieldSets.EcomFlds, 'AccountId__r.', fldSet);
         DmlHelper.addFieldsToSet(Schema.SObjectType.Contact.fieldSets.EcomFlds, 'Contact__r.', fldSet);
         DmlHelper.addFieldsToSet(Schema.SObjectType.Opportunity.fieldSets.EcomFlds, 'Opportunity__r.', fldSet);
         //query = ObjectHelper.getSOQLQuery('CSO_Tracking__c', new String[]{'AccountId__r.Paychex_CAID__c'}, true, false, false, false, true);
         query = DmlHelper.buildQueryFromSet(fldSet, 'CSO_Tracking__c');
         CacheManager.putOrg(CACHE_CSO_QUERY, query);
      }

      return query;
   } // getCSOTrackerQuery
   
   public static Map<String,CSO_Tracking__c> getCSOTrackerMap(Map<String,Ecommerce__c[]> ecomMap) {
      Map<String,CSO_Tracking__c> trackerMap = new Map<String,CSO_Tracking__c>();
      if (!ecomMap.isEmpty()) {
         String query = getCSOTrackerQuery();
         Set<String> caidSet = ecomMap.keySet();
         query += ' Where (AccountId__r.Paychex_CAID__c in :caidSet or CAID__c in :caidSet) order by CreatedDate desc ';
         System.debug('checkCSOTrackers query='+query);
         CSO_Tracking__c[] trackers = Database.query(query);
         for (CSO_Tracking__c tracker : trackers) {
            String caid = (String.isNotBlank(tracker.CAID__c) ? tracker.CAID__c : tracker.AccountId__r.Paychex_CAID__c);
            // make sure we only get the latest one
            if (caid != null && !trackerMap.containsKey(caid)) {
               trackerMap.put(caid, tracker);
            }
         }
      }
      return trackerMap;
   } // getCSOTrackerMap
   
   public static final String CACHE_ACCT_QUERY='EcomMethodsAccountQuery';
   public static String getAcctQuery() {
      String query = (String)CacheManager.getOrg(CACHE_ACCT_QUERY);
      if (query == null) {
         Set<String> fldSet = new Set<String>();
         DmlHelper.addFieldsToSet(Schema.SObjectType.Account.fieldSets.EcomFlds, '', fldSet);
         query = DmlHelper.buildQueryFromSet(fldSet, 'Account');
         CacheManager.putOrg(CACHE_ACCT_QUERY, query);
      }
      return query;
   } // getAcctQuery
   
   public static Map<String,Account> getAcctMap(Id[] acctIds, String[] caids, String[] cltNbrs) {
      Map<String,Account> acctMap = new Map<String,Account>();
      System.debug('getAcctMap acctIds='+acctIds.size()+' caids='+caids.size()+' cltNbrs='+cltNbrs.size());
      if (!acctIds.isEmpty() || !caids.isEmpty()) {
         // we don't want to query with blank values
         String[] queryCaids = (caids.isEmpty() ? new String[]{'ThisIsNotACaid'} : caids);
         Id[] queryAcctIds = (acctIds.isEmpty() ? new Id[]{'001000000000000'} : acctIds);
         String[] queryCltNbrs = (cltNbrs.isEmpty() ? new String[]{'NotACltNbr13'} : cltNbrs);
         String query = getAcctQuery();
         query += ' where Id in :queryAcctIds or Paychex_CAID__c in :queryCaids or EnterpriseClientNumber__c in :queryCltNbrs ';
         Account[] accts = Database.query(query);
         System.debug('getAcctMap accts='+accts.size());
         for (Account acct : accts) {
            acctMap.put(acct.Id, acct);
            if (String.isNotBlank(acct.Paychex_CAID__c)) {
               acctMap.put(acct.Paychex_CAID__c,acct);
            }
            if (String.isNotBlank(acct.EnterpriseClientNumber__c)) {
               acctMap.put(acct.EnterpriseClientNumber__c,acct);
            }
         } // for (Account acct : accts
      } // if (!acctIds.isEmpty()
      System.debug('getAcctMap acctMap='+acctMap.size());
      return acctMap;
   } // getAcctMap

   public static void setCsoField(CSO_Tracking__c tracker, Ecommerce__c ecom, String fieldName, Boolean alwaysUpdate) {
      System.debug('setCsoField fieldName='+fieldName);
      if (ecom.CSOMilestone__c && (tracker.LatestAction__c == null
                                  || ecom.SortOrder__c >= tracker.LatestAction__r.SortOrder__c)) {
         tracker.LatestAction__c = ecom.Id;
         csoTrackUpdateMap.put(tracker.Id, tracker);
      }
      if (String.isNotBlank(fieldName)) {
         try {
            // only set the field if it's not already set 
            if (alwaysUpdate || tracker.get(fieldName) == null) {
               Datetime logTime = (ecom.CompletedDateTime__c != null ? ecom.CompletedDateTime__c
                                      : (ecom.SubmittedDateTime__c != null ? ecom.SubmittedDateTime__c : ecom.CreatedDate));
               tracker.put(fieldName,logTime);
               csoTrackUpdateMap.put(tracker.Id, tracker);
            }
         } catch (Exception e) {
            StringHelper.addToProcessNotes(ecom,'Error logging to '+fieldName+': '+e.getMessage());
         }
      }

   } // setCsoField
    
   public static void checkFromPartRef(Id[] partRefIds, String[] mktgIds) {
      /*
      System.debug('checkPartRefNow partRefIds='+partRefIds.size()+' mktgIds='+mktgIds.size());
      // see if there are any ecom records for the mktgids passed in
      Ecommerce__c[] ecoms = getEcoms(null, mktgIds);
      if (ecoms.isEmpty()) {
          return;
      }
      // set the records so the batch will pick them up
      for (Ecommerce__c ecom : ecoms) {
         if (!ecom.Processed__c) {
            ecom.CheckCount__c = 0;
            ecom.CheckTime__c = Datetime.now();
         }
      }
      TriggerMethods.SKIP_TRIGGERS=true;
      update ecoms;
      //EcomBatch.launchBatch();
      TriggerMethods.SKIP_TRIGGERS=false;
      */
   } // checkFromPartRef

   public class EcomWrap {
      public Ecommerce__c ecom;
      //public Boolean ecomUpdated = false;
      public PartnerReferral__c partRef;
      public Referral_Partner__c refPart;
      public CSO_Tracking__c csoTracker;
      public Account acct;
      //public Boolean partRefUpdated = false;
      public Opportunity opp;
      public Boolean oppChanged = false;
      public Boolean oppIsInsert = false;
      // if more than one referral is created, link them together
      public ReferralJoin__c refJoin;

      // for the ancillary opportunities
      public OpportunityLineItem[] olis = new OpportunityLineItem[]{};
      public OpportunityContactRole[] ocrs = new OpportunityContactRole[]{};
      // the ancillary product information
      public AncWrap[] ancWraps = new AncWrap[]{};
      //public Map<String,AncWrap> ancMap = new Map<String,AncWrap>();
       
      public EcomWrap(Ecommerce__c p_ecom, PartnerReferral__c p_partRef, CSO_Tracking__c p_csoTracker, Account p_acct) {
         ecom = p_ecom;
         partRef = p_partRef;
         csoTracker = p_csoTracker;
         acct = p_acct;
         if (acct == null) {
            acct = (partRef != null ? partRef.Account__r : (csoTracker != null ? csoTracker.AccountId__r : null));
         }
         ecom.Account__c = (acct != null ? acct.Id : null);
         if (partRef != null) {
            refPart = (partRef?.Referral__c != null ? partRef.Referral__r.Referral_Partner__r : null);
            refJoin = (partRef?.Referral__c != null ? partRef.Referral__r.ReferralJoin__r : null);
            ecom.Lead__c = partRef.Lead__c;
            //ecom.Account__c = partRef.Account__c;
            ecom.Contact__c = partRef.Contact__c;
            ecom.Opportunity__c = partRef.Opportunity__c;
         } else if (csoTracker != null) {
            //ecom.Account__c = csoTracker.AccountId__c;
            ecom.Contact__c = csoTracker.Contact__c;
            ecom.Opportunity__c = csoTracker.Opportunity__c;
         }
      } // public EcomWrap
   } // class EcomWrap
    
   public static EcomWrap handleEcom(Ecommerce__c ecom, PartnerReferral__c partRef, CSO_Tracking__c csoTracker, Account acct) {
      System.debug('handleEcom ecom='+(ecom != null ? ecom.Company__c : 'No Ecom'));
      EcomWrap wrap = new EcomWrap(ecom,partRef,csoTracker,acct);
      ecom.PartnerReferral__c = (partRef != null ? partRef.Id : null);
      ecom.CSOTracking__c = (csoTracker != null ? csoTracker.Id : null);
      handleEcomRecord(wrap);

      return wrap;
   } // handleEcom
   
   public static void handleEcomRecord(EcomWrap wrap) {
      System.debug('handleEcomRecord action='+wrap.ecom.Action__c);
      StringHelper.addToProcessNotes(wrap.ecom,wrap.ecom.Action__c);
      //System.debug('handleEcomRecord ACTIONS_TO_PROCESS='+ACTIONS_TO_PROCESS);
      //System.debug('handleEcomRecord ACTIONS_ABANDONED='+ACTIONS_ABANDONED);
      if (wrap.csoTracker != null) {
         setCsoField(wrap.csoTracker, wrap.ecom, wrap.ecom.CSOTrackingFirst__c, false);
         setCsoField(wrap.csoTracker, wrap.ecom, wrap.ecom.CSOTrackingLatest__c, true);
         if (String.isNotBlank(wrap.ecom.PriorWages__c) && wrap.ecom.PriorWages__c != wrap.csoTracker.PriorWages__c) {
            wrap.csoTracker.PriorWages__c = wrap.ecom.PriorWages__c;
         }
         
         if (wrap.ecom.FirstCheckDate__c != null && wrap.csoTracker.FirstCheckDate__c != wrap.ecom.FirstCheckDate__c) {
            wrap.csoTracker.FirstCheckDate__c = wrap.ecom.FirstCheckDate__c;
         }
         if (wrap.ecom.FirstPayrollRunDate__c != null && wrap.csoTracker.FirstPayrollRunDate__c != wrap.ecom.FirstPayrollRunDate__c) {
            wrap.csoTracker.FirstPayrollRunDate__c = wrap.ecom.FirstPayrollRunDate__c;
         }
      } // if (wrap.csoTracker != null
       
      if (wrap.ecom.EnterpriseUpdate__c) {
         // if the account is found, update the account.
         // if the account is not found, do we only create based on the action?  
         // TODO - handle new clients
         updateFromEcomEnterprise(wrap.acct, wrap);
      } // if (wrap.ecom.EnterpriseUpdate__c
       
      //if (String.isNotBlank(wrap.ecom.Action__c) && ACTIONS_TO_PROCESS.contains(wrap.ecom.Action__c)) {
      // if the SortOrder has a positive value it's actionable.
      if (wrap.ecom.SortOrder__c > 0 || wrap.ecom.FirstPayrollRunDate__c != null) {
              
         // check to make sure not a previous form
         Decimal newStep = wrap.ecom.SortOrder__c;
         Decimal prevStep = (wrap.partRef != null && wrap.partRef.LatestEcommerce__c != null ? wrap.partRef.LatestEcommerce__r.SortOrder__c : -1);
         System.debug('handleEcomRecord newStep='+newStep+' prevStep='+prevStep);
         // make sure we don't get a previous step
         // TODO - do we assume they might go backwards for CSO?
         if (wrap.ecom.SortOrder__c > 0 && wrap.partRef != null && newStep < prevStep) {
            wrap.ecom.Processed__c = true;
            StringHelper.addToProcessNotes(wrap.ecom,'Skipped this ecom because it was an earlier step than the previous step processed. Previous Action='+wrap.partRef.LatestEcommerce__r.Action__c);
            ecomUpdateMap.put(wrap.ecom.Id,wrap.ecom);
            return;
         }
         updatePartRef(wrap);
         // Is there an opportunity stage defined for this action?
         Boolean hasOppStage = String.isNotBlank(wrap.ecom.OppStage__c);
         Boolean updateMktgStage = String.isBlank(wrap.ecom.OppStage__c);
         Account acct = wrap.acct;
         //Account acct = (wrap.partRef != null ? wrap.partRef.Account__r : (wrap.csoTracker != null ? wrap.csoTracker.AccountId__r : null));
         Contact ctct = (wrap.partRef != null ? wrap.partRef.Contact__r : (wrap.csoTracker != null ? wrap.csoTracker.Contact__r : null));
         Opportunity opp = (wrap.partRef != null && wrap.partRef.Referral__r != null ? wrap.partRef.Referral__r.Selling_Opportunity__r 
                            : (wrap.csoTracker != null ? wrap.csoTracker.Opportunity__r : null));
         System.debug('handleEcomRecord partRef.Lead__c='+(wrap.partRef != null ? wrap.partRef.Lead__c : null)+' opp='+(opp != null ? opp.Name : 'NoOpp')+' Payroll Started='+wrap.ecom.PayrollStarted__c+' hasRunDate='+(wrap.ecom.FirstPayrollRunDate__c != null));
         StringHelper.addToProcessNotes(wrap.ecom, 'updateFromEcom hasOppStage='+hasOppStage+' hasAcct='+(acct != null)+' Payroll Started='+wrap.ecom.PayrollStarted__c+' hasRunDate='+(wrap.ecom.FirstPayrollRunDate__c != null));
          
         if (wrap.ecom.PayrollStarted__c && wrap.ecom.FirstPayrollRunDate__c != null && acct != null) {
             StringHelper.addToProcessNotes(wrap.ecom, 'Payroll Started FirstPayrollRunDate__c='+wrap.ecom.FirstPayrollRunDate__c+' First_Run_Date__c='+acct.First_Run_Date__c);
             if (wrap.ecom.FirstPayrollRunDate__c != acct.First_Run_Date__c) {
                Account updateAcct = new Account(Id=acct.Id, First_Run_Date__c = wrap.ecom.FirstPayrollRunDate__c);
                StringHelper.addToProcessNotes(wrap.ecom,'Updated Account First Run Date');
                acctUpdateMap.put(updateAcct.Id,updateAcct);
             }
         } // if (wrap.ecom.PayrollStarted__c

         if (wrap.csoTracker != null) {
            // Need to update the CloseDate on the Opp if it changes
            // if the payroll runs update account also.
            handleFromCSO(wrap);
         } 
         if (acct != null || ctct != null) {
            updateFromEcom(acct, ctct, wrap, !hasOppStage);
         } else if (wrap.partRef != null && wrap.partRef.Lead__c != null && !wrap.partRef.Lead__r.IsConverted) {
            // first update the lead so we don't need to perform another update after the conversion
            Boolean changed = updateFromEcom(wrap.partRef.Lead__r, wrap, !hasOppStage);
            // have to convert the lead if we're going to set the opportunity

             if (hasOppStage) {
               if (changed) {
                  // remove from the update map
                  Lead updateLd = leadUpdateMap.remove(wrap.partRef.Lead__c);
                  if (updateLd != null) {
                     TriggerMethods.SKIP_TRIGGERS = true;
                     update updateLd;
                     TriggerMethods.SKIP_TRIGGERS = false;
                  }
               } // if (changed
               // convert the lead
               convertLead(wrap, wrap.partRef.Lead__r);
            } // if (!leadAllowed
         
            //updateFromEcom(partRef.Lead__r, ecom, 'TAL', true);
         }
         // do we create/update the opp? Partner and Referral should already exist
         System.debug('handleEcomRecord updateOpp partRef found='+(wrap.partRef != null)+' ref='+(wrap.partRef != null && wrap.partRef.Referral__c != null));
         if ((hasOppStage || wrap.ecom.FirstPayrollRunDate__c != null) && wrap.partRef != null && wrap.partRef.Referral__c != null) {
            handleOpps(wrap);
         } // if (updateOpp
         wrap.ecom.Processed__c = true;
         ecomUpdateMap.put(wrap.ecom.Id,wrap.ecom);
         handleAncillaries(wrap);
         System.debug('handleEcomRecord partRef.Lead__c='+wrap.partRef.Lead__c);
      } else if (wrap.ecom.AbandonedAction__c) {
         System.debug('handleEcomRecord in ACTIONS_ABANDONED');
         handleAbandoned(wrap);
      }

   } // handleEcomRecord
    
   public static void handleFromCSO(EcomWrap wrap) {
      if (wrap.ecom.FirstPayrollRunDate__c != null || String.isNotBlank(wrap.ecom.OppStage__c)) {
         // update the opp
         handleOppsCSO(wrap);
      } // if (wrap.ecom.FirstPayrollRunDate__c != null
   } // handleFromCSO
   
   public static String hbrEmail = Label.EcommerceHBREmail;
    
   public static Boolean handleAbandoned(EcomWrap wrap) {
      Boolean okay=true;
      if (wrap.partRef != null) {
         wrap.ecom.PartnerReferral__c = wrap.partRef.Id;
         wrap.ecom.Account__c = wrap.partRef.Account__c;
         wrap.ecom.Contact__c = wrap.partRef.Contact__c;
         wrap.ecom.Lead__c = wrap.partRef.Lead__c;
         wrap.ecom.Opportunity__c = wrap.partRef.Opportunity__c;
      }
      // TODO - do something different here if not in production?
      wrap.ecom.Processed__c = true;
      // see if it's already marked as abandoned
      Boolean alreadyAbandoned = (wrap.partRef != null && wrap.partRef.LatestEcommerce__c != null && wrap.partRef.LatestEcommerce__r.AbandonedAction__c);

      if (alreadyAbandoned) {
         StringHelper.addToProcessNotes(wrap.ecom,'Was previously abandoned. Previous Action='+wrap.partRef.LatestEcommerce__r.Action__c);
      } else {
         wrap.partRef.LatestEcommerce__c = wrap.ecom.Id;
         wrap.ecom.EmailAbandon__c = hbrEmail;
         // is this production?
         String sandboxName = Utilities.checkForProduction();
         // we want to send it to a "safe" email in sandboxes.
         wrap.ecom.EmailAbandonProspect__c = (String.isBlank(sandboxName) ? wrap.ecom.ContactEmail__c : hbrEmail);
         partRefUpdateMap.put(wrap.partRef.Id, wrap.partRef);
      }
      // do we need to do any actions? 
      ecomUpdateMap.put(wrap.ecom.Id,wrap.ecom);
      return okay;
   } // handleAbandoned
    
   public static Boolean handleOpps(EcomWrap wrap) {
      Boolean changed = false;
      wrap.opp = wrap.partRef.Referral__r.Selling_Opportunity__r;
      if (wrap.opp == null) {
          // create a new opp
          wrap.opp = createEcomOpp(wrap, ECOMMERCE, wrap.refPart, wrap.partRef.Referral__r);
          changed = true;
      }
      // update the fields
      if (wrap.opp != null && String.isNotBlank(wrap.ecom.OppStage__c)) {
         System.debug('handleOpps option1');
         changed = (checkOppRecordType(wrap) || changed);
         if (wrap.opp!=null && wrap.opp.Reason_Not_Sold__c!=null){
            // if we're setting the status in code, we need to make sure the reason not sold isn't populated (in case someone had made the opp not sold)
            wrap.opp.Reason_Not_Sold__c=null;
            wrap.opp.Reason_Not_Sold_Details__c=null;
            changed = true;
         }
         changed = fieldUpdated(wrap.opp, wrap.opp, 'StageName', wrap.ecom, 'OppStage__c', changed);
         changed = fieldUpdated(wrap.opp, wrap.opp, 'Employees_Paid_Per_Payroll__c', wrap.ecom, 'NumberOfEmployees__c', changed);
         changed = fieldUpdated(wrap.opp, wrap.opp, 'Frequency__c', wrap.ecom, 'FrequencyOpp__c', changed);
         changed = fieldUpdated(wrap.opp, wrap.opp, 'Check_Date__c', wrap.ecom, 'FirstCheckDate__c', changed);
         changed = fieldUpdated(wrap.opp, wrap.opp, 'CloseDate', wrap.ecom, 'FirstPayrollRunDate__c', changed);
      } else if (wrap.opp != null && wrap.ecom.FirstPayrollRunDate__c != null) {
         System.debug('handleOpps option2');
         changed = fieldUpdated(wrap.opp, wrap.opp, 'Check_Date__c', wrap.ecom, 'FirstCheckDate__c', changed);
         changed = fieldUpdated(wrap.opp, wrap.opp, 'CloseDate', wrap.ecom, 'FirstPayrollRunDate__c', changed);
      }
      wrap.oppChanged = changed;
      System.debug('handleOpps changed='+changed);
      return changed;
   } // handleOpps
   
   public static Boolean checkOppRecordType(EcomWrap wrap) {
      Boolean changed = false;
      if (wrap.opp != null && String.isNotBlank(wrap.ecom.OppRecordType__c)) {
         Map<String,Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
         SalesOrg__c salesOrg = SalesOrg__c.getInstance(ECOMMERCE);
         Id ecomRtId = null;
         if (salesOrg != null && String.isNotBlank(salesOrg.OpptyRecordTypeName__c) && rtMap.containsKey(salesOrg.OpptyRecordTypeName__c)) {
             ecomRtId = rtMap.get(salesOrg.OpptyRecordTypeName__c).getRecordTypeId();
         }
         Schema.RecordTypeInfo rtInfo = rtMap.get(wrap.ecom.OppRecordType__c);
         System.debug('checkOppRecordType rtInfo='+rtInfo);
         // don't change the record type if it's an ecom opportunity
         if (rtInfo != null && wrap.opp.RecordTypeId != ecomRtId && wrap.opp.RecordTypeId != rtInfo.getRecordTypeId()) {
            wrap.opp.RecordTypeId = rtInfo.getRecordTypeId();
            wrap.oppChanged = true;
            changed = true;
         }
      }
      return changed;
   } // checkOppRecordType
   
   public static Boolean handleOppsCSO(EcomWrap wrap) {
      Boolean changed = false;
      wrap.opp = wrap.csoTracker.Opportunity__r;
      if (wrap.opp != null) {
         changed = fieldUpdated(wrap.opp, wrap.opp, 'Check_Date__c', wrap.ecom, 'FirstCheckDate__c', changed);
         changed = fieldUpdated(wrap.opp, wrap.opp, 'CloseDate', wrap.ecom, 'FirstPayrollRunDate__c', changed);
         if (String.isNotBlank(wrap.ecom.OppStage__c) && wrap.opp.StageName != wrap.ecom.OppStage__c) {
            // only change the stage if it's higher.
            Map<String,OpportunityStage> oppStageMap = OpptyMethods.getOppStageMap();
            Decimal probCurrent = (oppStageMap.containsKey(wrap.opp.StageName) ? oppStageMap.get(wrap.opp.StageName).DefaultProbability : 0 );
            Decimal probNext = (oppStageMap.containsKey(wrap.ecom.OppStage__c) ? oppStageMap.get(wrap.ecom.OppStage__c).DefaultProbability : 100 );
            if (probNext > probCurrent) {
               changed = (checkOppRecordType(wrap) || changed);
               changed = fieldUpdated(wrap.opp, wrap.opp, 'StageName', wrap.ecom, 'OppStage__c', changed);
            }
            
         }
      } // if (wrap.opp != null

      wrap.oppChanged = changed;
      return changed;
   } // handleOpps

    
   public static Opportunity createEcomOpp(EcomWrap wrap, String salesOrg, Referral_Partner__c refPart, Referral__c ref) {
      CreateOppAndMeeting coam = new CreateOppAndMeeting(salesOrg);
      String prodName = (refPart != null ? refPart.Name : 'Ecommerce');
      String notes = 'refPart='+(refPart != null ? refPart.Name : 'Not Found!')+'; prodName='+prodName;
      Opportunity opp = coam.createOpp(wrap.ecom.Company__c, prodName);
      // so it uses the same stages as if it came from NSS
      opp.StageName = coam.refOppFirstStage;  
      opp.AccountId = wrap.ecom.Account__c;
      opp.OppSource__c='EcomMethods';
      if (wrap.partRef.Campaign__c != null) {
         opp.Campaign__c = wrap.partRef.Campaign__c;
      }
      if (wrap.partRef.Campaign__c != null && String.isNotBlank(wrap.partRef.Campaign__r.LeadSource__c)) {
         notes += '; LeadSource taken from Campaign ';
         opp.LeadSource = wrap.partRef.Campaign__r.LeadSource__c;
      } else {
         opp.LeadSource='eCommerce'; 
      }
      opp.NSS_Source__c=(refPart != null && String.IsNotBlank(refPart.NSS_Source__c) ? refPart.NSS_Source__c :'Inbound-Ecommerce');
      opp.OpportunityType__c=(refPart != null && String.IsNotBlank(refPart.SellingOpportunityType__c) ? refPart.SellingOpportunityType__c :'Payroll');
      // TODO - parameter on the referral partner?
      opp.Payroll_Platform__c='Flex';
      StringHelper.addToProcessNotes(opp,notes);
      if (ref != null) {
         if (ref.Id != null) {
            opp.ReferralLookup__c=ref.Id;
         } else {
            opp.ReferralLookup__r=ref;
         }
      } // if (ref != null
      //opp.ReferralLookup__c=refId;
      User ecomUser = getEcomUser();
      if (ecomUser != null) {
         opp.OwnerId = ecomUser.Id;
      }
      // create a new contact role
      OpportunityContactRole ocr = new OpportunityContactRole(Opportunity=opp, ContactId=wrap.ecom.Contact__c, IsPrimary=true);
      wrap.ocrs.add(ocr);
       
      return opp;
   } // createEcomOpp
    
   public static void convertLead(EcomWrap wrap, Lead ld) {
      System.debug('convertLead ld='+ld.Company);
      StringHelper.addToProcessNotes(wrap.ecom,'convertLead');
      //User runningUser = UserHelper.getRunningUser();
      //String salesOrg = (runningUser != null ? runningUser.Sales_Org__c : UserHelper.SO_CORE);
      ReferralController rc = new ReferralController('Ecommerce');
      // to setup the lead as expected
      rc.handleLeadId(ld.Id);
      rc.primaryLead=ld;
      // to make sure the triggers fire
      TriggerMethods.SKIP_TRIGGERS=false;
      TriggerMethods.clearVariables();
      LeadMethods.LEAD_BEFORE_EXECUTING=false;
      LeadMethods.LEAD_AFTER_EXECUTING=false;
      CreateOppAndMeeting.NON_VISUAL_CONTEXT=true;
      rc.convertLead();
      wrap.ecom.Account__c=(rc.acct != null ? rc.acct.Id : null);
      wrap.ecom.Contact__c=(rc.ctct != null ? rc.ctct.Id : null);
      System.debug('convertlead acct='+(rc.acct != null));
      System.debug('convertlead ctct='+(rc.ctct != null));
      if (rc.acct != null) {
         User ecomUser = getEcomUser();
         Account tempAcct = new Account(Id=rc.acct.Id);
         tempAcct.OwnerId = (ecomUser != null ? ecomUser.Id : UserInfo.getUserId());
         tempAcct.Hold_Out__c = true;
         tempAcct.Hold_Out_Expiration__c=null;
         tempAcct.Permanent_Hold_Out_Description__c = ECOMMERCE;
         Boolean origValue = ZipCheckOwner.SKIP_TRIGGERS;
         ZipCheckOwner.SKIP_TRIGGERS=true;
         update tempAcct;
         ZipCheckOwner.SKIP_TRIGGERS=origValue;
      }
   } // convertLead
    
   public static Map<String,Referral_Partner__c> refPartMap = new Map<String,Referral_Partner__c>();
    
   public static Boolean setRefPartner(EcomWrap wrap) {
      Boolean changed = false;
      if (wrap.refJoin != null && wrap.refJoin.Id != null && wrap.partRef != null && wrap.partRef.Referral__r != null && wrap.partRef.Referral__r.ReferralJoin__c != wrap.refJoin.Id) {
          wrap.partRef.Referral__r.ReferralJoin__c = wrap.refJoin.Id;
          changed = true;
      }
      if (wrap != null && wrap.ecom != null && String.isNotBlank(wrap.ecom.ReferralPartnerName__c)) {
         Referral_Partner__c refPartMatch = refPartMap.get(wrap.ecom.ReferralPartnerName__c);
         System.debug('setRefPartner ReferralPartnerName__c='+wrap.ecom.ReferralPartnerName__c+' foundInMap='+(refPartMatch != null));
         if (refPartMatch == null) {
            Referral_Partner__c[] refParts = ReferralQueries.selectRefPartnersCache(ECOMMERCE, null);
            if (refParts != null) {
               for (Referral_Partner__c refPart : refParts) {
                  if (refPart.Name == wrap.ecom.ReferralPartnerName__c) {
                     refPartMatch = refPart;
                     refPartMap.put(wrap.ecom.ReferralPartnerName__c,refPart);
                  }
               }
            } // if (refParts != null) 
         } // if (retVal == null) {
         System.debug('setRefPartner ReferralPartnerName__c='+wrap.ecom.ReferralPartnerName__c+' refPartMatch found='+(refPartMatch != null));
         //if (refPartMatch != null && wrap.partRef != null && wrap.partRef.Referral__r != null && wrap.partRef.Referral__r.Referral_Partner__c != refPartMatch.Id) {
         if (refPartMatch != null && wrap.partRef != null && wrap.partRef.Referral__r != null 
               && (wrap.ecom.Action__c== ACTION_OCC1 || wrap.partRef.Referral__r.Referral_Partner__c == null)) {
            System.debug('setRefPartner setting Referral_Partner__c id='+refPartMatch.Id);
            wrap.partRef.Referral__r.Referral_Partner__c = refPartMatch.Id;
            wrap.refPart = refPartMatch;
            changed = true;
         }
      } // if (wrap != null && wrap.ecom != null
      return changed;
   } // setRefPartner
    
   public static String NOT_SOLD='Not Sold';
   public static String DISQUALIFIED='Disqualified';
    
   // TODO - can I combine this with the other save routine? 
   public static void checkSaveAncillaries(EcomWrap[] wraps) {
      // if there are new referrals, we want to insert them first. 
      Referral__c[] insertRefs = new Referral__c[]{};
      // store the update refs. We'll add the insert ones to this list after they're saved. 
     // Map<Id,Referral__c> updateRefMap = new Map<Id,Referral__c>();
      //Referral__c[] updateRefs = new Referral__c[]{};
      // we are only inserting opportunities for ancillaries, not updating. 
      Opportunity[] insertOpps = new Opportunity[]{};
      // inserting OLIs
      OpportunityLineItem[] insertOlis = new OpportunityLineItem[]{};
          
      for (EcomWrap wrap : wraps) {
         for (AncWrap aWrap : wrap.ancWraps) {
            if (aWrap.ref != null) {
               if (aWrap.ref.Id == null) {
                   insertRefs.add(aWrap.ref);
                   // if there's also an opportunity, we're going to have to update the referral after the opp saves
                   //if (aWrap.opp != null) {
                   //   updateRefs.add(aWrap.ref);
                   //}
               } else {
                   refUpdateMap.put(aWrap.ref.Id,aWrap.ref);
                   //updateRefs.add(aWrap.ref);
               }
            }
         } // for (AncWrap aWrap : wrap.ancWraps

      } // for (EcomWrap wrap
      System.debug('checkSaveAncillaries wraps='+wraps.size()+' insertRefs='+insertRefs.size()+' refUpdateMap='+refUpdateMap.size()+' insertOpps='+insertOpps.size());
       
      if (insertRefs.isEmpty() && refUpdateMap.isEmpty()) {
         return;
      }
      if (!insertRefs.isEmpty()) {
         // skip the trigger on insert
         ReferralTriggerActions.SKIP_TRIGGER = true;
         DmlHelper.performDML2(insertRefs, DmlHelper.DML_INSERT, CLASSNAME, 'checkSaveAncillaries', 'Insert Anc Refs', false);
         //updateRefs.addAll(insertRefs);
         ReferralTriggerActions.SKIP_TRIGGER = false;
      } // if (!insertRefs.isEmpty
      
      for (EcomWrap wrap : wraps) {
         for (AncWrap aWrap : wrap.ancWraps) {
            if (aWrap.opp != null) {
               // set the lookup if it needs it
               if (aWrap.ref != null && aWrap.ref.Id != null && aWrap.opp.ReferralLookup__c != aWrap.ref.Id) {
                  aWrap.opp.ReferralLookup__c =aWrap.ref.Id;
                  aWrap.opp.ReferralLookup__r = null;
               }
               insertOpps.add(aWrap.opp);
            }
            
         } // for (AncWrap aWrap : wrap.ancWraps
      } // for (EcomWrap wrap : wraps

      if (!insertOpps.isEmpty()) {
         // don't need the trigger on insert of an opportunity
         OpptyMethods.SKIP_OPPTY_TRIGGERS = true;
         DmlHelper.performDML2(insertOpps, DmlHelper.DML_INSERT, CLASSNAME, 'checkSaveAncillaries', 'Insert Anc Opps', false);
         OpptyMethods.SKIP_OPPTY_TRIGGERS = false;
      } // if (!insertOpps
       
      for (EcomWrap wrap : wraps) {
         for (AncWrap aWrap : wrap.ancWraps) {
            if (aWrap.oli != null && aWrap.opp != null && aWrap.opp.Id != null) {
               aWrap.oli.OpportunityId = aWrap.opp.Id;
               insertOlis.add(aWrap.oli);
            }
            
         } // for (AncWrap aWrap : wrap.ancWraps
      } // for (EcomWrap wrap : wraps

      if (!insertOlis.isEmpty()) {
         // don't need the trigger on insert of an opportunity
         OpptyLineItem.SKIP_TRIGGER = true;
         DmlHelper.performDML2(insertOlis, DmlHelper.DML_INSERT, CLASSNAME, 'checkSaveAncillaries', 'Insert Anc Opp Line Items', false);
         OpptyLineItem.SKIP_TRIGGER = false;
      } // if (!insertOpps

      // update the referrals that now have the selling opportunity set
      for (EcomWrap wrap : wraps) {
         for (AncWrap aWrap : wrap.ancWraps) {
            if (aWrap.ref != null && aWrap.opp != null && aWrap.opp.Id != null && aWrap.ref.Selling_Opportunity__c == null) {
               aWrap.ref.Selling_Opportunity__c = aWrap.opp.Id;
               refUpdateMap.put(aWrap.ref.Id,aWrap.ref);
            }
         } // for (AncWrap aWrap : wrap.ancWraps
      } // for (EcomWrap wrap : wraps
    
      //if (!updateRefs.isEmpty()) {
         // we want to make sure the trigger fires when setting the selling opp.
      //   ReferralTriggerActions.SKIP_TRIGGER = false;
      //   DmlHelper.performDML2(updateRefs, DmlHelper.DML_UPDATE, CLASSNAME, 'checkSaveAncillaries', 'Update Anc Refs', false);
      //   ReferralTriggerActions.SKIP_TRIGGER = false;
      //} // if (!insertRefs.isEmpty

   } // checkSaveAncillaries

   public static Map<Id,Referral__c> refUpdateMap = new Map<Id,Referral__c>();
   public static Map<Id,CSO_Tracking__c> csoTrackUpdateMap = new Map<Id,CSO_Tracking__c>();

    
   // save all of the records associated with this process
   public static void checkSaveRecs(EcomWrap[] wraps) {
      System.debug('checkSaveRecs wraps='+wraps.size());
      EcomWrap[] oppWraps = new EcomWrap[]{};
      EcomWrap[] oppWrapInserts = new EcomWrap[]{};
      // to check for open opportunities
      Id[] acctIds = new Id[]{};
      // the opportunity types we're going to check for
      String[] oppTypes = new String[]{};
      // only need to keep one wrap per account id
      Map<Id,EcomWrap> oppWrapInsertMap = new Map<Id,EcomWrap>();
      Opportunity[] oppInserts = new Opportunity[]{};
      Opportunity[] oppUpdates = new Opportunity[]{};
      // creating new opp contact roles
      OpportunityContactRole[] ocrInserts = new OpportunityContactRole[]{};
      //Map<Id,Referral__c> refUpdateMap = new Map<Id,Referral__c>();
          
      Id[] oppIds = new Id[]{};
      for (EcomWrap wrap : wraps) {
         if (wrap.partRef != null) {
            wrap.ecom.PartnerReferral__c = wrap.partRef.Id;
            ocrInserts.addAll(wrap.ocrs);
            // see if we need to set the referral partner on the referral. So we don't have to wait until the opportunity stage
            if (setRefPartner(wrap)) {
                refUpdateMap.put(wrap.partRef.Referral__c,wrap.partRef.Referral__r);
            }
         } // if (wrap.partRef != null
          
         if (wrap.oppChanged) {
            oppWraps.add(wrap);
            if (wrap.opp.Id == null) {
               wrap.oppIsInsert = true;
               oppInserts.add(wrap.opp);
               oppWrapInsertMap.put(wrap.opp.AccountId, wrap);
               oppTypes.add(wrap.opp.OpportunityType__c);
            } else {
               oppUpdates.add(wrap.opp);
               oppIds.add(wrap.opp.Id);
            }
         }
      } // for (EcomWrap wrap : wraps

      // to make sure we don't skip the triggers
      TriggerMethods.SKIP_TRIGGERS=false;
      TriggerMethods.clearVariables();
      LeadMethods.LEAD_BEFORE_EXECUTING=false;
      LeadMethods.LEAD_AFTER_EXECUTING=false;
      OpptyMethods.SKIP_OPPTY_TRIGGERS=false;
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=false;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=false;
      DG_LMF_Service.ALREADY_RAN_SET.clear();
      
      if (!csoTrackUpdateMap.isEmpty()) {
         DmlHelper.performDML2(csoTrackUpdateMap.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'checkSaveRecs', 'Update CSO Trackers', false);
      }
       
      System.debug('checkSaveRecs oppWrapInsertMap='+oppWrapInsertMap.size());
      // check for any other open opportunities linked to the accounts for the soon to be inserted opps
      if (!oppWrapInsertMap.isEmpty()) {
         Opportunity[] openOpps = [Select Id, Name, OwnerId, AccountId, CloseDate, StageName, IsClosed, IsWon, OpportunityType__c, Payroll_Units__c
                                         ,Non_Payroll_Units__c, Employees_Paid_Per_Payroll__c
                                     from Opportunity
                                    Where AccountId in :oppWrapInsertMap.keySet()
                                      and OpportunityType__c in :oppTypes
                                      and OppSource__c != 'EcomMethods'
                                      and IsClosed = false];
         SalesOrg__c salesOrg = SalesOrg__c.getInstance(ECOMMERCE);
         RecordType__c rtSetting = null;
         if (salesOrg != null && String.isNotBlank(salesOrg.OpptyRecordTypeName__c)) {
            rtSetting = RecordType__c.getInstance(salesOrg.OpptyRecordTypeName__c);
         }
         System.debug('checkSaveRecs openOpps='+openOpps.size()+' rtSetting='+(rtSetting != null ? rtSetting.Name : 'null'));
         // all opportunities selected should be closed
         for (Opportunity opp : openOpps) {
            opp.StageName = DISQUALIFIED;
            opp.Reason_Not_Sold__c = (rtSetting != null && String.isNotBlank(rtSetting.FirstRunReasonLost__c) ? rtSetting.FirstRunReasonLost__c : 'Ecommerce');
            oppUpdates.add(opp);
            EcomWrap wrap = oppWrapInsertMap.get(opp.AccountId);
            if (wrap != null) {
               StringHelper.addToProcessNotes(wrap.ecom,'Closed '+opp.Name+' Opportunity due to new Ecom Opp created');
            }
            // create a chatter message
            ChatterMentionPost.createChatterMentionPost(opp.Id, new Id[]{opp.OwnerId}, new String[]{Label.EcomOppCloseChatterMsg}
                                                        ,true, false);
         } // for (Opportunity opp : openOpps
         ChatterMentionPost.checkPostFeedElements();
      } // if (!acctIds.isEmpty

      System.debug('checkSaveRecs oppUpdates='+oppUpdates.size()+' oppInserts='+oppInserts.size()+' oppWraps='+oppWraps.size());
      DmlHelper.performDML2(oppUpdates, DmlHelper.DML_UPDATE, CLASSNAME, 'checkSaveRecs', 'Update Opps', false);
      DmlHelper.performDML2(oppInserts, DmlHelper.DML_INSERT, CLASSNAME, 'checkSaveRecs', 'Insert Opps', false);
       
     // Referral__c[] refUpdates = new Referral__c[]{};
          
      OpportunityLineItem[] insertOlis = new OpportunityLineItem[]{};
      OpportunityLineItem[] updateOlis = new OpportunityLineItem[]{};
      OpportunityLineItem[] deleteOlis = new OpportunityLineItem[]{};

      if (!oppWraps.isEmpty()) {
         oppUpdates.clear();
         OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
          
         // if we inserted opportunities, we need to update the other records to link up.
         // get the ecommerce products
         Map<String,PricebookEntry> pbeMap = getPbeMap();
         
         // get any existing OpportunityLineItems
         Map<Id,Map<String,OpportunityLineItem>> existingOliMap = getExistingOlis(oppIds);

         for (EcomWrap wrap : oppWraps) {
            if (wrap.opp.Id != null) {
               if (wrap.partRef != null && wrap.partRef.Opportunity__c != wrap.opp.Id) {
                  wrap.partRef.Opportunity__c = wrap.opp.Id;
                  partRefUpdateMap.put(wrap.partRef.Id, wrap.partRef);
               }
               if (wrap.ecom.Opportunity__c != null || wrap.ecom.Opportunity__c != wrap.opp.Id) {
                  wrap.ecom.Opportunity__c = wrap.opp.Id;
               }
             
               //Boolean refChanged = setRefPartner(wrap);
               Boolean refChanged = false;
                
               if (wrap.partRef != null && wrap.partRef.Referral__c != null && wrap.partRef.Referral__r.Selling_Opportunity__c != wrap.opp.Id) {
                  wrap.partRef.Referral__r.Selling_Opportunity__c = wrap.opp.Id;
                  wrap.partRef.Referral__r.Original_Employee_Count__c = wrap.opp.Employees_Paid_Per_Payroll__c;
                  // make sure these lookups are populated.
                  wrap.partRef.Referral__r.SourceContact__c = wrap.ecom.Contact__c;
                  wrap.partRef.Referral__r.Account__c = wrap.ecom.Account__c;
                  refChanged = true;
               }
               
               if (refChanged) {
                  //refUpdates.add(wrap.partRef.Referral__r);
                  refUpdateMap.put(wrap.partRef.Referral__c,wrap.partRef.Referral__r);
               }
            } // if (wrap.opp.Id != null
            if (String.isNotBlank(wrap.ecom.ProductInfo__c)) {
               handleOppProducts(wrap, existingOliMap.get(wrap.opp.Id), pbeMap, insertOlis, updateOlis, deleteOlis, oppUpdates);
            }
         } // for (EcomWrap wrap : oppInsertWraps
         
         DmlHelper.performDML2(oppUpdates, DmlHelper.DML_UPDATE, CLASSNAME, 'checkSaveRecs', 'Update Opps after Units', false);
      } // if (!oppWraps.isEmpty
       
      PartnerReferralHelper.TRIGGER_ALREADY_RAN=true;
      // make sure the trigger fires for referral when selling opp is set.
      ReferralTriggerActions.SKIP_TRIGGER = false;
      System.debug('checkSaveRecs partRefUpdateMap='+partRefUpdateMap.size()+' leadUpdateMap='+leadUpdateMap.size()+' ctctInserts='+ctctInserts.size()+' acctInserts='+acctInserts.size()+' acctUpdateMap='+acctUpdateMap.size());
      DmlHelper.performDML2(partRefUpdateMap.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'checkSaveRecs', 'Update Partner Referrals', false);
      DmlHelper.performDML2(leadUpdateMap.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'checkSaveRecs', 'Update Leads', false);
      DmlHelper.performDML2(ctctUpdateMap.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'checkSaveRecs', 'Update Contacts', false);
      DmlHelper.performDML2(ctctInserts, DmlHelper.DML_INSERT, CLASSNAME, 'checkSaveRecs', 'Insert Contacts', false);
      DmlHelper.performDML2(acctInserts, DmlHelper.DML_INSERT, CLASSNAME, 'checkSaveRecs', 'Insert Accounts', false);
      DmlHelper.performDML2(acctUpdateMap.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'checkSaveRecs', 'Update Accounts', false);
      DmlHelper.performDML2(refUpdateMap.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'checkSaveRecs', 'Update Referrals', false);
      
      if (!acctInserts.isEmpty()) {
         // if we have inserted accounts, we want to make sure they're linked to the ecom records
         for (EcomWrap wrap : wraps) {
            if (wrap.acct != null && wrap.acct.Id != null) {
               wrap.ecom.Account__c = wrap.acct.Id;
               ecomUpdateMap.put(wrap.ecom.Id, wrap.ecom);
            }
         } // for (EcomWrap wrap : wraps
      } // if (!acctInserts.isEmpty
       
       // we want to make sure we don't get back into the trigger for ecom records
      TriggerMethods.SKIP_TRIGGERS=true;
      DmlHelper.performDML2(ecomUpdateMap.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'checkSaveRecs', 'Update Ecommerce Records', false);
      checkRecsForPurge(ecomUpdateMap.values());
      // clear out the relation
      for (OpportunityContactRole ocr : ocrInserts) {
          if (ocr.Opportunity != null && ocr.Opportunity.Id != null) {
              ocr.OpportunityId = ocr.Opportunity.Id;
              ocr.Opportunity = null;
          }
      } // for (OpportunityContactRole ocr : ocrInserts
      DmlHelper.performDML2(ocrInserts, DmlHelper.DML_INSERT, CLASSNAME, 'checkSaveRecs', 'Insert Opportunity Contact Roles', false);
      // we don't need the triggers firing for this at this point.
      OpptyLineItem.SKIP_TRIGGER=true;
      DmlHelper.performDML2(insertOlis, DmlHelper.DML_INSERT, CLASSNAME, 'checkSaveRecs', 'Insert Opportunity Line Items', false);
      DmlHelper.performDML2(updateOlis, DmlHelper.DML_UPDATE, CLASSNAME, 'checkSaveRecs', 'Update Opportunity Line Items', false);
      DmlHelper.performDML2(deleteOlis, DmlHelper.DML_DELETE, CLASSNAME, 'checkSaveRecs', 'Delete Opportunity Line Items', false);
      ErrorLog.checkSave();
      
   } // checkSaveRecs
   
   public static void handleOppProducts(EcomWrap wrap, Map<String,OpportunityLineItem> existingOliMap, Map<String,PricebookEntry> pbeMap
                                       ,OpportunityLineItem[] insertOlis, OpportunityLineItem[] updateOlis, OpportunityLineItem[] deleteOlis
                                       ,Opportunity[] oppUpdates) {
      System.debug('handleOppProducts prodInfo='+wrap.ecom.ProductInfo__c);
      String prodNotes = '';
      String[] prodCodes = wrap.ecom.ProductInfo__c.split(',');
      // the last value in the list is going to be the price
      // we'll put the price on the first product in the list alphabetically for now
      Decimal price = 0;
      Integer multiplier = Integer.valueOf(wrap.ecom.FrequencyMultiplier__c);
      try {
         price = (prodCodes.size() > 1 ? Decimal.valueOf(prodCodes.remove(prodCodes.size()-1)) : 0);
      } catch (Exception e) {
         System.debug('handleOppProducts e='+e.getMessage());
      }
      Decimal annualRev = price * multiplier;
      System.debug('handleOppProducts prodCodes='+prodCodes.size()+' price='+price+' multiplier='+multiplier+' annualRev='+annualRev);
       
      prodCodes.sort();

      // so we know when we handle the first in the list
      Boolean firstInList = true;
      OpportunityLineItem revenueOli = null;
      Integer payrollUnits = 0;
      Integer nonPayrollUnits = 0;                        
      // make sure we have all in the list
      for (String prodCode : prodCodes) {
         PricebookEntry entry = pbeMap.get(prodCode);
         // see if there's an existing product. If there is, see if it needs to be updated
         OpportunityLineItem oli = (existingOliMap != null ? existingOliMap.remove(prodCode) : null);
         prodNotes += ('\nprodcode '+prodCode+' entry='+(entry != null)+' oli='+(oli != null));
         if (oli == null && entry != null) {
            oli = createOli(wrap.opp, entry);
            //oli = new OpportunityLineItem(OpportunityId=wrap.opp.Id, PricebookEntryId=entry.Id, ServiceDate=wrap.opp.CloseDate, Quantity=1, TotalPrice=0);
         } else {
            System.debug('handleOppProducts No Entry found for prodCode '+prodCode);
            //prodNotes += '\nNo Entry found for prodCode '+prodCode;
         }
         if (oli != null) {
            // default all to zero
            oli.TotalPrice = 0;
            payrollUnits = payrollUnits + (oli.Payroll_Unit__c != null ? Integer.valueOf(oli.Payroll_Unit__c) : 0);
            nonPayrollUnits = nonPayrollUnits + (oli.Non_Payroll_Unit__c != null ? Integer.valueOf(oli.Non_Payroll_Unit__c) : 0);
             
            if (revenueOli == null || entry.Product2.Is_Payroll_Unit__c) {
               revenueOli = oli;
            }
            if (oli.Id == null) {
               insertOlis.add(oli); 
            } else {
               updateOlis.add(oli);
            }
         } // if (oli != null
         
      } // for (String prodCode : prodCodes
                                           
      if (wrap.opp.Payroll_Units__c != payrollUnits || wrap.opp.Non_Payroll_Units__c != nonPayrollUnits)           {
         wrap.opp.Payroll_Units__c = payrollUnits;
         wrap.opp.Non_Payroll_Units__c = nonPayrollUnits;
         oppUpdates.add(wrap.opp);
      }                          
                                           
      if (revenueOli != null) {
         revenueOli.TotalPrice = annualRev;
      }
      // if there are any remaining products in the map, we're going to remove them
      if (existingOliMap != null && !existingOliMap.isEmpty()) {
         deleteOlis.addAll(existingOliMap.values());
      }
      StringHelper.addToProcessNotes(wrap.ecom, prodNotes);
      System.debug('handleOppProducts insertOlis='+insertOlis.size()+' updateOlis='+updateOlis.size()+' deleteOlis='+deleteOlis.size()+' oppUpdates='+oppUpdates.size());
   } // handleOppProducts
    
   public static OpportunityLineItem createOli(Opportunity opp, PricebookEntry entry) {
      OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=opp.Id, PricebookEntryId=entry.Id, ServiceDate=opp.CloseDate, Quantity=1, TotalPrice=0);
      oli.Payroll_Unit__c = (entry.Product2.Is_Payroll_Unit__c ? 1 : 0);
      oli.Non_Payroll_Unit__c = (entry.Product2.Is_Non_Payroll_Unit__c ? 1 : 0);
      opp.Payroll_Units__c = (opp.Payroll_Units__c != null ? opp.Payroll_Units__c : 0) + oli.Payroll_Unit__c;
      opp.Non_Payroll_Units__c = (opp.Non_Payroll_Units__c != null ? opp.Non_Payroll_Units__c : 0) + oli.Non_Payroll_Unit__c;
      return oli;
   } // createOli
    
   public static Map<String,PricebookEntry> getPbeMap() {
      Pricebook2 ecomPriceBook = new ProductQuery().getPricebookNoCache(ECOMMERCE);
      // put the pricebook entries in a map for easy reference
      Map<String,PricebookEntry> pbeMap = new Map<String,PricebookEntry>();
      for (PricebookEntry entry : ecomPriceBook.PricebookEntries) {
         if (String.isNotBlank(entry.Product2.StockKeepingUnit)) {
            pbeMap.put(entry.Product2.StockKeepingUnit, entry);
         } 
         if (String.isNotBlank(entry.Product2.cafsl__Part_Number__c)) {
            pbeMap.put(entry.Product2.cafsl__Part_Number__c, entry);
         } 
         if (String.isNotBlank(entry.Product2.ProductCode)) {
            pbeMap.put(entry.Product2.ProductCode, entry);
         }
      }
      return pbeMap;
   } // getPbeMap

   public static Map<Id,Map<String,OpportunityLineItem>> getExistingOlis(Id[] oppIds) {
      Map<Id,Map<String,OpportunityLineItem>> existingOliMap = new Map<Id,Map<String,OpportunityLineItem>>();
      // if this is an existing opportunity, retrieve products
      if (!oppIds.isEmpty()) {
         OpportunityLineItem[] oppProds = [Select Id, OpportunityId, Product2Id, Product2.ProductCode, Product2.StockKeepingUnit, Product2.cafsl__Part_Number__c
                                                 ,PricebookEntryId
                                                 ,Quantity, ServiceDate, TotalPrice, Payroll_Unit__c, Non_Payroll_Unit__c
                                             from OpportunityLineItem
                                            Where OpportunityId in :oppIds];
          
         for (OpportunityLineItem oli : oppProds) {
            Map<String,OpportunityLineItem> oliMap = (existingOliMap.containsKey(oli.OpportunityId) ? existingOliMap.get(oli.OpportunityId) : new Map<String,OpportunityLineItem>());
            if (String.isNotBlank(oli.Product2.StockKeepingUnit)) {
               oliMap.put(oli.Product2.StockKeepingUnit, oli);
            } else if (String.isNotBlank(oli.Product2.cafsl__Part_Number__c)) {
               oliMap.put(oli.Product2.cafsl__Part_Number__c, oli);
            } else {
               oliMap.put(oli.Product2.ProductCode, oli);
            }
            existingOliMap.put(oli.OpportunityId, oliMap);
         } // for (OpportunityLineItem
      } // if (wrap.opp.Id != null
      return existingOliMap;
   } // getExistingOlis
    
   public class AncWrap{
      public AncWrap(String p_prodCode) {
          prodCode = p_prodCode;
      }
      public String prodCode;
      public Referral__c ref;
      public Referral_Partner__c refPart;
      public Opportunity opp;
      public OpportunityLineItem oli;
   } // class AncWrap
   
   public static void handleAncillaries(EcomWrap wrap) {
      if (String.isBlank(wrap.ecom.AncillaryProducts__c) && String.isBlank(wrap.partRef.EcomAncillaryBody__c)) {
         System.debug('handleAncillaries Ancillary Products is blank');
         // nothing needs to be done here.
         return;
      }
      // in the later stages we don't get the ecom products on the ecom form, so if we've previously received them, continue on.
      Boolean checkRefsOnly = (String.isNotBlank(wrap.partRef.EcomAncillaryBody__c) && !wrap.ecom.OCCAction__c); //  FLEX_ACTIONS.contains(wrap.ecom.Action__c));
       
      // see if there are any other referrals
      Referral__c[] refs = [Select Id, Name, Account__c
                                             ,ProductReferred__c
                                             ,ReferralJoin__c
                                             ,Referral_Partner__c
                                             ,Referral_Partner__r.Id
                                             ,Referral_Partner__r.Name
                                             ,Referral_Partner__r.Partner_Type__c
                                             ,Referral_Partner__r.ProductCodes__c
                                             ,Referral_Partner__r.Sales_Org__c
                                             ,Referral_Partner__r.NSS_Source__c
                                             ,Referral_Partner__r.QueueName__c
                                             ,Referral_Partner__r.Selling_Opp_RecordTypeId__c
                                             ,Referral_Partner__r.SellingOpportunityType__c
                                             ,SourceContact__c
                                             ,SourceLead__c
                                             ,Selling_Opportunity__c
                                             ,Selling_Opportunity__r.Id
                                             ,Selling_Opportunity__r.OwnerId
                                             ,Selling_Opportunity__r.Owner.Id
                                             ,Selling_Opportunity__r.Owner.Email
                                             ,Selling_Opportunity__r.Owner.IsActive
                              From Referral__c
                             Where PartnerReferral__c = :wrap.partRef.Id
                               and Id != :wrap.partRef.Referral__c];
      // find referral partners by the product codes
      Map<String,PricebookEntry> pbeMap = getPbeMap();
      if (!checkRefsOnly) {
          
      }
      Set<String> prodCodeSet = (String.isNotBlank(wrap.ecom.AncillaryProducts__c) ? new Set<String>(wrap.ecom.AncillaryProducts__c.split(',')) : new Set<String>());
      System.debug('handleAncillaries existing refs='+refs.size()+' prodCodeSet='+prodCodeSet.size());
      // get the full names of the products to display for the email - save to the partner referral
      String[] ancProds = new String[]{};
      for (String prodCode : prodCodeSet) {
          PricebookEntry pbe = pbeMap.get(prodCode);
          if (pbe != null) {
             String prodDesc = prodCode+'-'+pbe.Product2.Name;
             ancProds.add(prodDesc);
          }
      } // for (String prodCode : prodCodeSet
       
      StringHelper.addToProcessNotes(wrap.ecom,'handleAncillaries ancProds='+ancProds.size());
      // when we get the ecommerce from flex, won't have ancillary products, so make sure we don't blank them out.
      if (!ancProds.isEmpty()) {
         String ancString = String.join(ancProds,', ');
         if (ancString != wrap.partRef.EcomAncillaryBody__c) {
            wrap.partRef.EcomAncillaryBody__c = ancString;
            //if (wrap.ecom.AncillaryFirstEmail__c) {
            //   wrap.partRef.EcomAncillaryEmail1__c = hbrEmail;
            //}
            //if (wrap.ecom.AncillarySecondEmail__c) {
            //   wrap.partRef.EcomAncillaryEmail2__c = hbrEmail;
            //}
            partRefUpdateMap.put(wrap.partRef.Id, wrap.partRef);
         }
      } // if (!ancProds.isEmpty
       
      Map<String,AncWrap> ancMap = new Map<String,AncWrap>();
      for (String prodCode : prodCodeSet) {
         ancMap.put(prodCode, new AncWrap(prodCode));
      }
      // see if the existing referrals match the product codes
      // we're not going to check if we need to delete - since they can submit referrals through the the submit Referral form this will get complicated.
       
      // separate out the ones that match the product codes.
      Referral__c[] matchingRefs = new Referral__c[]{};
      // do we need to update the lookup fields on the referrals?
      Referral__c[] updateRefs = new Referral__c[]{};
      //AncWrap[] matchedProdCodes = new AncWrap[]{};
          
      for (Referral__c ref : refs) {
         String matchingProdCode = null;
         if (prodCodeSet.isEmpty() || prodCodeSet.contains(ref.ProductReferred__c)) {
            matchingProdCode = ref.ProductReferred__c;
            prodCodeSet.remove(ref.ProductReferred__c);
         }
         /*
         String[] refProdCodes = ((ref.Referral_Partner__c != null && String.isNotBlank(ref.Referral_Partner__r.ProductCodes__c)) ? ref.Referral_Partner__r.ProductCodes__c.split(',') : new String[]{});
         System.debug('handleAncillaries refProdCodes='+refProdCodes+' prodCodeSet='+prodCodeSet);
         // use match so we don't accidentally match on multiple product codes and add a referral__c record twice to the list
         for (String refProdCode: refProdCodes) {
            if (prodCodeSet.contains(refProdCode)) {
               matchingProdCode = refProdCode;
            }
            // remove any that exist
            prodCodeSet.remove(refProdCode);
         }
         */
         System.debug('handleAncillaries matchingProdCode='+matchingProdCode);
         if (matchingProdCode != null) {
            matchingRefs.add(ref);
            AncWrap aWrap = ancMap.get(matchingProdCode);
            if (aWrap != null) {
               aWrap.ref = ref;
               aWrap.refPart = ref.Referral_Partner__r;
               // clear so we don't try to save the reference
               ref.Referral_Partner__r = null;
               //matchedProdCodes.add(aWrap);
            } else if (prodCodeSet.isEmpty()) {
               // if this is a later stage, we still want to update the records
               aWrap = new AncWrap(matchingProdCode);
               aWrap.ref = ref;
               aWrap.refPart = ref.Referral_Partner__r;
               // clear so we don't try to save the reference
               ref.Referral_Partner__r = null;
               ancMap.put(matchingProdCode, aWrap);
            }
         } // if (matchingProdCode != null
         System.debug('handleAncillaries after refProdCodes prodCodeSet='+prodCodeSet);
      } // for (Referral__c
       
     System.debug('handleAncillaries prodCodeSet='+prodCodeSet.size());
      
     if (!prodCodeSet.isEmpty()) {
         // if there are any remaining product codes, find the correct referral partners and create the referrals.
         Referral_Partner__c[] allRefParts = ReferralQueries.selectRefPartnersCache(ECOMMERCE, null);
         System.debug('handleAncillaries allRefParts='+allRefParts.size());
         for (String prodCode : prodCodeSet) {
            for (Referral_Partner__c refPart : allRefParts) {
               System.debug('handleAncillaries prodCode='+prodCode+' refPart.ProductCodes__c='+refPart.ProductCodes__c);
               if (String.isNotBlank(refPart.ProductCodes__c) && refPart.ProductCodes__c.contains(prodCode)) {
                  System.debug('handleAncillaries create new referral');
                  // create a referral record
                  Referral__c newRef = createReferral(wrap, refPart);
                  // mark the product code so we know when we create the opp
                  newRef.ProductReferred__c = prodCode;
                  matchingRefs.add(newRef);
                  AncWrap aWrap = ancMap.get(prodCode);
                  if (aWrap != null) {
                     System.debug('handleAncillaries found existing AncWrap to set new referral');
                     aWrap.ref = newRef;
                     aWrap.refPart = refPart;
                     //matchedProdCodes.add(aWrap);
                  }

                  break;
               } // if (String.isNotBlank(refPart.ProductCodes__c) && refPart.ProductCodes__c.contains
            } // for (Referral_Partner__c refPart : allRefParts
         } // for (String prodCode : prodCodeSet
         
      } // if (!prodCodeSet.isEmpty()
       
      System.debug('handleAncillaries wrap.ecom.OppStage__c='+wrap.ecom.OppStage__c+' ancMap='+ancMap.size());
      // if there's an opportunity stage, make sure we have opportunities for the referrals.
      Boolean sendEmail = false; 
      
      for (AncWrap aWrap : ancMap.values()) {
         // do not need to do anything if we don't have a referral at this point
         System.debug('handleAncillaries hasRef='+(aWrap.ref != null));
         if (aWrap.ref != null) {
            Boolean refOwnerChanged = false;
            Boolean refChanged = (aWrap.ref.Id == null);
            System.debug('handleAncillaries ecom.Account='+wrap.ecom.Account__c+' ref.Account='+aWrap.ref.Account__c);
            if ((wrap.ecom.Account__c != null && wrap.ecom.Account__c != aWrap.ref.Account__c)
                       || (wrap.ecom.Contact__c != null && wrap.ecom.Contact__c != aWrap.ref.SourceContact__c)) {
               System.debug('handleAncillaries setting account and contact on referral');
               aWrap.ref.Account__c = wrap.ecom.Account__c;
               aWrap.ref.SourceContact__c = wrap.ecom.Contact__c;
               refChanged = true;
            }
            if (wrap.ecom.AncillaryFirstEmail__c) {
               wrap.partRef.EcomAncillaryEmail1__c = hbrEmail;
               partRefUpdateMap.put(wrap.partRef.Id, wrap.partRef);
            }
            if (wrap.ecom.AncillarySecondEmail__c) {
                // to handle the opportunities that will be re-routed to another group.
                if (aWrap.refPart != null && String.isNotBlank(aWrap.refPart.QueueName__c)) {
                    Group que = new UserHelper().getQueue(aWrap.refPart.QueueName__c);
                    System.debug('handleAncillaries queueName='+aWrap.refPart.QueueName__c+' que found='+(que != null));
                    refChanged = true;
                    if (que != null) {
                       aWrap.ref.OwnerId = que.Id;
                       refOwnerChanged = true;
                    } else {
                       StringHelper.addToprocessNotes(aWrap.ref,'Unable to find Queue named '+aWrap.refPart.QueueName__c);
                       StringHelper.addToprocessNotes(wrap.partRef,'Unable to find Queue named '+aWrap.refPart.QueueName__c+' to assign Ancillary');
                       partRefUpdateMap.put(wrap.partRef.Id, wrap.partRef);
                    }
                } // if (aWrap.refPart != null &&
            } // if (wrap.ecom.AncillarySecondEmail__c
            // create a referral join record if it doesn't exist. 
            if (wrap.refJoin == null) {
               wrap.refJoin = new ReferralJoin__c();
               insert wrap.refJoin;
            }
            if (wrap.refJoin != null && wrap.refJoin.Id != null) {
               aWrap.ref.ReferralJoin__c = wrap.refJoin.Id;
            }
            if (String.isNotBlank(wrap.ecom.OppStage__c) && aWrap.ref.Selling_Opportunity__c == null) {
               // create the opp 
               Opportunity opp = createEcomOpp(wrap, aWrap.refPart.Sales_Org__c, aWrap.refPart, aWrap.ref);
               aWrap.opp = opp;
               //ref.Selling_Opportunity__r=opp;
               refChanged = true;
             
               // create the products
               if (String.isNotBlank(aWrap.ref.ProductReferred__c) && pbeMap.containsKey(aWrap.ref.ProductReferred__c)) {
                  PricebookEntry entry = pbeMap.get(aWrap.ref.ProductReferred__c);
                  // try pulling the price from the ecom record
                  Decimal price = 0;
                  if (String.isNotBlank(wrap.ecom.AncillaryPrices__c)) {
                     try {
                         Integer multiplier = Integer.valueOf(wrap.ecom.FrequencyMultiplier__c);
                         price = Decimal.valueOf(wrap.ecom.AncillaryPrices__c) * multiplier;
                     } catch (Exception e) {
                        StringHelper.addToProcessNotes(wrap.ecom,'Unabled to understand '+wrap.ecom.AncillaryPrices__c);
                     }
                  } // if (String.isNotBlank(wrap.ecom.AncillaryPrices__c)
                  aWrap.oli = createOli(opp, entry);
                  awrap.oli.TotalPrice=price;

                  //aWrap.oli = new OpportunityLineItem(Opportunity=opp, PricebookEntryId=entry.Id, ServiceDate=opp.CloseDate, Quantity=1, TotalPrice=price);
                  //wrap.olis.add(oli);
               }
            } else if (aWrap.ref.Selling_Opportunity__c != null && wrap.ecom.AncillarySecondEmail__c && !refOwnerChanged) {
               // we're going to set the email address for the second ancillary email if the referral is not being sent to a queue
               User ecomUser = getEcomUser();
               // if the selling opportunity owner is not equal to the ecommerce user, use that email.
               if (ecomUser != null && aWrap.ref.Selling_Opportunity__r.Owner.Id != ecomUser.Id && aWrap.ref.Selling_Opportunity__r.Owner.IsActive
                       && aWrap.ref.Selling_Opportunity__r.Owner.Email != wrap.partRef.EcomAncillaryEmail2__c) {
                  wrap.partRef.EcomAncillaryEmail2__c = aWrap.ref.Selling_Opportunity__r.Owner.Email;
               } 
               partRefUpdateMap.put(wrap.partRef.Id, wrap.partRef);
            } // if (ref.Selling_Opportunity__c == null
             
            // default it to the hybrid rep email box
            if (wrap.partRef.EcomAncillaryEmail2__c == null && wrap.ecom.AncillarySecondEmail__c) {
               wrap.partRef.EcomAncillaryEmail2__c = hbrEmail;
               partRefUpdateMap.put(wrap.partRef.Id, wrap.partRef);
            }


            System.debug('handleAncillaries refChanged='+refChanged);
            if (refChanged) {
               wrap.ancWraps.add(aWrap);
            }
         } // if (aWrap.ref != null
      } // for (AncWrap aWrap : wrap.ancMap.values

   } // handleAncillaries
    
   public static Referral__c createReferral(EcomWrap wrap, Referral_Partner__c refPart) {
      PartRefWrapper prw = new PartRefWrapper(wrap.partRef);
      String refName = prw.getName()+(refPart != null ? '-'+refPart.Name : '').left(PartRefWrapper.REF_NAME_SIZE);
      Referral__c ref = new Referral__c(Name=refName, PartnerReferral__c=wrap.partRef.Id);
      ref.Account__c = wrap.partRef.Account__c;
      ref.NbrOfEmployees__c = wrap.partRef.NumberOfEmployees__c;
      ref.Campaign__c = wrap.partRef.Campaign__c;
      ref.SourceContact__c = wrap.partRef.Contact__c;
      ref.SourceLead__c = wrap.partRef.Lead__c;
      ref.ReferralEntry__c = wrap.partRef.Source__c;
      ref.SellingLeadSource__c = wrap.partRef.LeadSource__c; 
      ref.CreatedByProcess__c = 'EcomMethods';
      ref.Referral_Partner__c = (refPart != null ? refPart.Id : null); 
      //ref.Referral_Partner__r = refPart;
      return ref;
   } // createReferral
    
   // reset the maps if we need to
   public static void clearSaveMaps() {
      acctUpdateMap.clear();
      ctctUpdateMap.clear();
      acctInserts.clear();
      ctctInserts.clear();
      leadUpdateMap.clear();
      partRefUpdateMap.clear();
      ecomUpdateMap.clear();
   } // clearSaveMaps
    
   public static Map<Id,Account> acctUpdateMap = new Map<Id,Account>(); 
   public static Map<Id,Contact> ctctUpdateMap = new Map<Id,Contact>();
   public static Account[] acctInserts = new Account[]{};
   public static Contact[] ctctInserts = new Contact[]{};
   public static Map<Id,Lead> leadUpdateMap = new Map<Id,Lead>();
   public static Map<Id,PartnerReferral__c> partRefUpdateMap = new Map<Id,PartnerReferral__c>();
   public static Map<Id,Ecommerce__c> ecomUpdateMap = new Map<Id,Ecommerce__c>();
    
   public static Boolean updatePartRef(EcomWrap wrap) {
      Boolean changed = false;
      if (wrap.partRef != null && wrap.ecom != null){
         PartnerReferral__c updatePartRef = new PartnerReferral__c(Id=wrap.partRef.Id);
         changed = fieldUpdated(wrap.partRef,wrap.partRef,'Company__c',wrap.ecom,'Company__c', changed);
         changed = fieldUpdated(wrap.partRef,wrap.partRef,'StreetAddress__c',wrap.ecom,'StreetAddress__c', changed);
         changed = fieldUpdated(wrap.partRef,wrap.partRef,'City__c',wrap.ecom,'City__c', changed);
         changed = fieldUpdated(wrap.partRef,wrap.partRef,'State__c',wrap.ecom,'State__c', changed);
         changed = fieldUpdated(wrap.partRef,wrap.partRef,'ZipPostalCode__c',wrap.ecom,'PostalCode__c', changed);
         changed = fieldUpdated(wrap.partRef,wrap.partRef,'NumberOfEmployees__c',wrap.ecom,'NumberOfEmployees__c', changed);

         changed = fieldUpdated(wrap.partRef,wrap.partRef,'FirstName__c',wrap.ecom,'ContactFirstName__c', changed);
         changed = fieldUpdated(wrap.partRef,wrap.partRef,'LastName__c',wrap.ecom,'ContactLastName__c', changed);
         changed = fieldUpdated(wrap.partRef,wrap.partRef,'Email__c',wrap.ecom,'ContactEmail__c', changed);
         changed = fieldUpdated(wrap.partRef,wrap.partRef,'Phone__c',wrap.ecom,'ContactPhone__c', changed);
         
         changed = fieldUpdated(wrap.partRef,wrap.partRef,'CEID__c',wrap.ecom,'CEID__c', changed);
         changed = fieldUpdated(wrap.partRef,wrap.partRef,'CAID__c',wrap.ecom,'CAID__c', changed);
         changed = fieldUpdated(wrap.partRef,wrap.partRef,'FEIN__c',wrap.ecom,'FEIN__c', changed);
         changed = fieldUpdated(wrap.partRef,wrap.partRef,'ClientNbr__c',wrap.ecom,'ClientNbr__c', changed);
          
         // set the latest ecommerce record only if it has a sort order
         if (wrap.ecom.SortOrder__c > 0 && wrap.partRef.LatestEcommerce__c != wrap.ecom.Id) {
            changed = true;
            wrap.partRef.LatestEcommerce__c = wrap.ecom.Id;
         }
         if (changed) {
            partRefUpdateMap.put(wrap.partRef.Id, wrap.partRef);
         }
      }
      return changed;
   } // updatePartRef
   
   public static Boolean updateFromEcom(Lead ld, EcomWrap wrap, Boolean updateLd) {
      Boolean changed = false;
      //ecom.MarketingStage__c = targetStage;
      StringHelper.addToProcessNotes(wrap.ecom, 'updateFromEcom has ld='+(ld != null && !ld.IsConverted)+' updateLd='+updateLd);
      if (ld != null && !ld.IsConverted) {
         Map<String,Schema.RecordTypeInfo> byNameMap = Lead.SObjectType.getDescribe().getRecordTypeInfosByName();
         Schema.RecordTypeInfo ecomRt = byNameMap.get(LEAD_RT_NAME);
         String ldNotes = 'Updating Lead from '+wrap.ecom.Name+' ecomRt found='+(ecomRt != null);
         wrap.ecom.Lead__c=ld.Id;
         Lead ldToUpdate = new Lead(Id=ld.Id, ProcessNotes__c=ld.ProcessNotes__c);
         if (updateLd) {
            String compareStage = checkStage(ld.Lead_Stage__c, wrap.ecom.MktgStage__c);
            if (ld.Lead_Stage__c != compareStage) {
               changed = true;
               ldToUpdate.Lead_Stage__c = compareStage;
               ldNotes += '; updated Lead Stage to '+compareStage;
            }
         }
         // set the EcommerceHoldoutDate__c so we know how long we should display a banner to the user
         //if (ld.EcommerceHoldoutDate__c == null || ld.EcommerceHoldoutDate__c < Date.today()) {
         //   HoldOut_Dictionary__c hod = HoldOut_Dictionary__c.getInstance(ECOMMERCE);
         //   Integer nbrDays = (hod != null && hod.InitialNbrDays__c != null ? Integer.valueOf(hod.InitialNbrDays__c) : 90);
         //   ld.EcommerceHoldoutDate__c = Date.today().addDays(nbrDays);
         //}
         User ecomUser = getEcomUser();
         ldNotes += '; ecomUser='+(ecomUser != null ? ecomUser.Name : 'Not Found');
         if (ecomUser != null && ld.OwnerId != ecomUser.Id) {
            ldToUpdate.OwnerId = ecomUser.Id;
            changed = true;
            ldNotes += '; Changed lead owner';
         }
         if (ecomRt != null && ld.RecordTypeId != ecomRt.getRecordTypeId()) {
            ldToUpdate.RecordTypeId = ecomRt.getRecordTypeId();
            changed = true;
            ldNotes += '; Changed RecordType to '+LEAD_RT_NAME;
         }
         if (!ld.Hold_Out__c || ld.Hold_Out_Reason__c != ECOMMERCE) {
            ldToUpdate.Hold_Out__c = true;
            // no date on the holdout?? 
            ldToUpdate.Hold_Out_Expiration__c=null;
            ldToUpdate.Hold_Out_Reason__c = ECOMMERCE;
            changed = true;
            ldNotes += '; Set Holdout';
         } // if (!ld.Hold_Out__c
             
         changed = fieldUpdated(ld,ldToUpdate,'Company',wrap.ecom,'Company__c', changed);
         changed = fieldUpdated(ld,ldToUpdate,'DBA__c',wrap.ecom,'DBA__c', changed);
         changed = fieldUpdated(ld,ldToUpdate,'Federal_ID_Number__c',wrap.ecom,'FEIN__c', changed);
         // TODO - do we need a translation here?
         changed = fieldUpdated(ld,ldToUpdate,'Frequency__c',wrap.ecom,'FrequencyAccount__c', changed);
         changed = fieldUpdated(ld,ldToUpdate,'Paychex_CAID__c',wrap.ecom,'CAID__c', changed);
         changed = fieldUpdated(ld,ldToUpdate,'Paychex_CEID__c',wrap.ecom,'CEID__c', changed);
         changed = fieldUpdated(ld,ldToUpdate,'Street',wrap.ecom,'StreetAddress__c', changed);
         changed = fieldUpdated(ld,ldToUpdate,'City',wrap.ecom,'City__c', changed);
         changed = fieldUpdated(ld,ldToUpdate,'State',wrap.ecom,'State__c', changed);
         changed = fieldUpdated(ld,ldToUpdate,'PostalCode',wrap.ecom,'PostalCode__c', changed);
         changed = fieldUpdated(ld,ldToUpdate,'Country',wrap.ecom,'Country__c', changed);
         //changed = fieldUpdated(ld,'NumberOfEmployees',ecom,'NumberOfEmployees__c', changed);
         changed = fieldUpdated(ld,ldToUpdate,'NumberOfEmployees', Integer.valueOf(wrap.ecom.NumberOfEmployees__c), changed);
         // TODO - need to verify what industry type is actually returning
         changed = fieldUpdated(ld,ldToUpdate,'Industry',wrap.ecom,'IndustryType__c', changed);

         changed = fieldUpdated(ld,ldToUpdate,'FirstName',wrap.ecom,'ContactFirstName__c', changed);
         changed = fieldUpdated(ld,ldToUpdate,'LastName',wrap.ecom,'ContactLastName__c', changed);
         changed = fieldUpdated(ld,ldToUpdate,'Email',wrap.ecom,'ContactEmail__c', changed);
         changed = fieldUpdated(ld,ldToUpdate,'Phone',wrap.ecom,'ContactPhone__c', changed);
         //changed = fieldUpdated(ld,'Title',ecom,'FEIN__c', changed);

         if (changed) {
            // set the lead for update
            StringHelper.addToProcessNotes(ldToUpdate,ldNotes);
            leadUpdateMap.put(ldToUpdate.Id,ldToUpdate);
         } 
      } // if (ld != null)
      return changed;
   } // updateFromEcom

    
   public static Boolean updateFromEcom(Account acct, Contact ctct, EcomWrap wrap, Boolean updateCtct) {
      System.debug('updateFromEcom acct='+(acct != null));
      Boolean changed = false;
      Boolean hasOppStage = String.isNotBlank(wrap.ecom.OppStage__c);
      StringHelper.addToProcessNotes(wrap.ecom, 'updateFromEcom has acct='+(acct != null)+' has ctct='+(ctct != null)+' updateCtct='+updateCtct+' hasOppStage='+hasOppStage);
      wrap.ecom.MarketingStage__c = wrap.ecom.MktgStage__c;
      User ecomUser = getEcomUser();
       
      if (acct != null) {
         wrap.ecom.Account__c = acct.Id;
         Account updateAcct = (acctUpdateMap.containsKey(acct.Id) ? acctUpdateMap.get(acct.Id) : new Account(Id=acct.Id));
         changed = setFromEcom(acct, updateAcct, wrap.ecom, true);

         if (wrap.partRef != null) {
            //ldNotes += '; ecomUser='+(ecomUser != null ? ecomUser.Name : 'Not Found');
            if (ecomUser != null && acct.OwnerId != ecomUser.Id) {
               updateAcct.OwnerId = ecomUser.Id;
               changed = true;
               //ldNotes += '; Changed lead owner';
            }

            // set the hold out at the opportunity stage
            if (!acct.Hold_Out__c || acct.Permanent_Hold_Out_Description__c != ECOMMERCE) {
               updateAcct.Hold_Out__c = true;
               updateAcct.Hold_Out_Expiration__c=null;
               updateAcct.Permanent_Hold_Out_Description__c = ECOMMERCE;
               changed = true;
            } // if (hasOppStage
              
         } // if (wrap.partRef != null
          
         if (changed) {
            // set the account for update
            acctUpdateMap.put(updateAcct.Id,updateAcct);
         } 
      } // if (acct != null
      
      if (ctct != null) {
         wrap.ecom.Contact__c = ctct.Id;
         Contact ctctToUpdate = new Contact(Id=ctct.Id);
         // if it's an opportunity stage, the contact stage will be handled in the DG code.
         if (updateCtct && !hasOppStage) {
            String compareStage = checkStage(ctct.Contact_Stage__c, wrap.ecom.MktgStage__c);
            StringHelper.addToProcessNotes(wrap.ecom,'compareStage='+compareStage+' ctct Stage='+ctct.Contact_Stage__c);
            if (ctct.Contact_Stage__c != compareStage) {
               changed = true;
               ctctToUpdate.Contact_Stage__c = compareStage;
            }
         }
         changed = fieldUpdated(ctct,ctctToUpdate,'FirstName',wrap.ecom,'ContactFirstName__c', false);
         changed = fieldUpdated(ctct,ctctToUpdate,'LastName',wrap.ecom,'ContactLastName__c', changed);
         changed = fieldUpdated(ctct,ctctToUpdate,'Email',wrap.ecom,'ContactEmail__c', changed);
         changed = fieldUpdated(ctct,ctctToUpdate,'Phone',wrap.ecom,'ContactPhone__c', changed);
         //changed = fieldUpdated(ctct,'Title',wrap.ecom,'Title', changed);
         changed = fieldUpdated(ctct,ctctToUpdate,'User_Name__c',wrap.ecom,'Username__c', changed);
         
         if (wrap.partRef != null) {

            if (ecomUser != null && ctct.OwnerId != ecomUser.Id) {
               ctctToUpdate.OwnerId = ecomUser.Id;
               changed = true;
            }
            if (ctct.Hold_Out__c) {
               // remove the contact holdout to follow the account
               ctctToUpdate.Hold_Out__c = false;
               ctctToUpdate.Hold_Out_Expiration__c=null;
               ctctToUpdate.Hold_Out_Reason__c=null;
               changed = true;
            }
         } // if (wrap.partRef != null

         if (changed) {
            // set the contact for update
            ctctUpdateMap.put(ctctToUpdate.Id,ctctToUpdate);
         }
      } // if (ctct != null)

      System.debug('updateFromEcom AuthorizingLastName__c='+wrap.ecom.AuthorizingLastName__c);
      // if there's an authorized person
      if (wrap.ecom.AuthorizingLastName__c != null) {
         checkAuthorizedContact(acct,ctct,wrap);
      }
      return changed;
   } // updateFromEcom
   
   // are we allowing the company name to be updated on an existing account record from enterprise?
   public static Boolean allowCompanyNameUpdate=(Label.EcomMethods_UpdateCompanyName=='Y');
   // are we allowing the child in a combo relationship's name to be updated?
   public static Boolean allowComboChildNameUpdate=(Label.EcomMethods_UpdateComboChildName=='Y');
    
   public static Boolean updateFromEcomEnterprise(Account acct, EcomWrap wrap) {
      Boolean changed = false;
      StringHelper.addToProcessNotes(wrap.ecom, 'updateFromEcomEnterprise has acct='+(acct != null));
       
      // we'll create a new account here
      if (acct == null) {
         System.debug('updateFromEcomEnterprise check with DuplicateHelper');
         // Use DuplicateHelper to see if we can find a match.
         Account checkAccount = new Account(Site='DuplicateCheckOnly');
         setFromEcom(checkAccount, checkAccount, wrap.ecom, true);
         // set the same address for billing and shipping
         fieldUpdated(checkAccount,checkAccount,'BillingStreet',wrap.ecom,'LegalAddress__Street__s', true);
         fieldUpdated(checkAccount,checkAccount,'BillingCity',wrap.ecom,'LegalAddress__City__s', true);
         fieldUpdated(checkAccount,checkAccount,'BillingState',wrap.ecom,'LegalAddress__StateCode__s', true);
         fieldUpdated(checkAccount,checkAccount,'BillingPostalCode',wrap.ecom,'LegalAddress__PostalCode__s', true);
         fieldUpdated(checkAccount,checkAccount,'BillingCountry',wrap.ecom,'LegalAddress__CountryCode__s', true);
         fieldUpdated(checkAccount,checkAccount,'ShippingStreet',wrap.ecom,'LegalAddress__Street__s', true);
         fieldUpdated(checkAccount,checkAccount,'ShippingCity',wrap.ecom,'LegalAddress__City__s', true);
         fieldUpdated(checkAccount,checkAccount,'ShippingState',wrap.ecom,'LegalAddress__StateCode__s', true);
         fieldUpdated(checkAccount,checkAccount,'ShippingPostalCode',wrap.ecom,'LegalAddress__PostalCode__s', true);
         fieldUpdated(checkAccount,checkAccount,'ShippingCountry',wrap.ecom,'LegalAddress__CountryCode__s', true);
         // try to find a match based on fed id 
         DuplicateHelper.DupeResult[] results = DuplicateHelper.findDuplicates(new Account[]{checkAccount}); 
         Integer nbrResults = (!results.isEmpty() && results[0].hasResults ? results[0].acctIds.size() : 0);
         if (nbrResults > 0) {
            // we'll take the first one that doesn't have a CAID
            Map<String,Account> acctMap = getAcctMap(results[0].acctIds, new String[]{}, new String[]{});
            for (Account checkAcct : acctMap.values()) {
               if (String.isBlank(checkAcct.Paychex_CAID__c) || checkAcct.Paychex_CAID__c == wrap.ecom.CAID__c) {
                   acct = checkAcct;
                   break;
               }
            }

         }
         StringHelper.addToProcessNotes(wrap.ecom, 'Results found from DuplicateHelper='+nbrResults+' acct='+(acct != null));
      } // if (acct == null
      // if there still isn't an account, set the record to try again if not at the max.
      if (acct == null) {

         // do we create an account yet? We want to be able to try a few times first. 
         Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('EcomBatchClientLegal');
         Integer nbrTimes = (abc != null && abc.NbrOfAttempts__c != null ? Integer.valueOf(abc.NbrOfAttempts__c) : 2);
         Integer nextAttempt = (abc != null && abc.Minutes_till_Launch__c != null ? Integer.valueOf(abc.Minutes_till_Launch__c) : 4);
         // this should get incremented before we get in here  (by the EcomBatch class), but just in case...
         wrap.ecom.CheckCount__c = (wrap.ecom.CheckCount__c == null ? 1 : wrap.ecom.CheckCount__c);
         System.debug('updateFromEcomEnterprise nbrTimes='+nbrTimes+' nextAttempt='+nextAttempt+' CheckCount__c='+wrap.ecom.CheckCount__c);
         if (wrap.ecom.CheckCount__c < nbrTimes) {
            // if we don't have an account record, we're not going to create one until we hit the limit.
            // change the checktime to this value rather than the default from the batch.
            wrap.ecom.CheckTime__c = Datetime.now().addMinutes(nextAttempt);
            return false;
         }
         // we're using this field to determine if we create an account based on the information
         if (!abc.SaveAttachments__c) {
            wrap.ecom.CheckTime__c = null;
            wrap.ecom.Processed__c=true;
            return false;
         }
         // this is just a place holder
         acct = new Account();
      }
      System.debug('updateFromEcomEnterprise acct='+(acct != null)+' action='+wrap.ecom.Action__c);
      //if (acct == null) {
      //   return false;
      //}
      Account updateAcct = (acct.Id == null ? acct 
                              : acctUpdateMap.containsKey(acct.Id) ? acctUpdateMap.get(acct.Id) : new Account(Id=acct.Id));
      wrap.acct = (wrap.acct == null ? updateAcct : wrap.acct);

      if (acct != null) {
         // we would only allow a child to be updated if the fed ids are different, otherwise could be a combo
         Boolean isChild = (acct.Id != null && acct.SalesParent__c != null);
         Boolean isChildWeUpdate = (allowComboChildNameUpdate && isChild
                                     && String.isNotBlank(acct.Federal_ID_Number__c) 
                                     && acct.Federal_ID_Number__c != acct.SalesParent__r.Federal_ID_Number__c);
         // if this is a new record or we turned on the flag to allow the name to update
         Boolean setCompanyName = (acct.Id == null || (allowCompanyNameUpdate));
         system.debug('updateFromEcomEnterprise isChild='+isChild+' isChildWeUpdate='+isChildWeUpdate+' setCompanyName='+setCompanyName);
         wrap.ecom.Processed__c = true;
         wrap.ecom.Account__c = acct.Id;
         changed = setFromEcom(acct, updateAcct, wrap.ecom, (setCompanyName && (!isChild || isChildWeUpdate)));
         system.debug('updateFromEcomEnterprise updateAcct.Id='+updateAcct.Id+' Paychex_CEID__c='+updateAcct.Paychex_CEID__c);
         if (updateAcct.Id == null && String.isNotBlank(updateAcct.Paychex_CEID__c)) {
            // see if there's an account with the same ceid
            Account[] parentAccts = [Select Id, Name, isParent__c, RecordTypeId from Account where Paychex_CEID__c=:updateAcct.Paychex_CEID__c and isChild__c=false limit 1];
            system.debug('updateFromEcomEnterprise parentAccts='+parentAccts.size());
            if (!parentAccts.isEmpty()) {
               updateAcct.SalesParent__c = parentAccts[0].Id;
               if (parentAccts[0].RecordTypeId != null) {
                  updateAcct.RecordTypeId = parentAccts[0].RecordTypeId;
               }
               updateAcct.Create_Junction__c = true;
            }
            if (updateAcct.RecordTypeId == null) {
               Map <String,Schema.RecordTypeInfo> rtMap = Account.sObjectType.getDescribe().getRecordTypeInfosByName();
               Schema.RecordTypeInfo rtInfo = rtMap.get(RecordTypeHelper.CORE_ACCOUNT);
               updateAcct.RecordTypeId = rtInfo.getRecordTypeId();
            }
         }
          
         if (changed) {
            if (updateAcct.Id != null) {
               // set the account for update
               acctUpdateMap.put(updateAcct.Id,updateAcct);
            } else {
               acctInserts.add(updateAcct);
            }
         } 
      } // if (acct != null
      
      return changed;
   } // updateFromEcomEnterprise
   
   public static Boolean setFromEcom(Account acct, Account updateAcct, Ecommerce__c ecom, Boolean updateCompanyName) {
      Boolean changed = false;
      if (updateCompanyName) {
         changed = fieldUpdated(acct,updateAcct,'Name',ecom,'Company__c', false);
      }
      changed = fieldUpdated(acct,updateAcct,'DBA__c',ecom,'DBA__c', changed);
      changed = fieldUpdated(acct,updateAcct,'EnterpriseClientNumber__c',ecom,'ClientNbr__c', changed);
      if (String.isNotBlank(ecom.BranchNbr__c) && String.isNotBlank(ecom.ClientNbr__c)) {
         String acctNbr = ecom.BranchNbr__c+'-'+ecom.ClientNbr__c;
         if (acctNbr != acct.AccountNumber) {
            changed = true;
            updateAcct.AccountNumber = acctNbr;
         }
      }
      changed = fieldUpdated(acct,updateAcct,'Federal_ID_Number__c',ecom,'FEIN__c', changed);
      // TODO - do we need a translation here?
      changed = fieldUpdated(acct,updateAcct,'Frequency__c',ecom,'FrequencyAccount__c', changed);
      changed = fieldUpdated(acct,updateAcct,'Paychex_CAID__c',ecom,'CAID__c', changed);
      changed = fieldUpdated(acct,updateAcct,'Paychex_CEID__c',ecom,'CEID__c', changed);

      if (String.isNotBlank(ecom.StreetAddress__c)) {
         changed = fieldUpdated(acct,updateAcct,'BillingStreet',ecom,'StreetAddress__c', changed);
         changed = fieldUpdated(acct,updateAcct,'BillingCity',ecom,'City__c', changed);
         changed = fieldUpdated(acct,updateAcct,'BillingState',ecom,'State__c', changed);
         changed = fieldUpdated(acct,updateAcct,'BillingPostalCode',ecom,'PostalCode__c', changed);
         changed = fieldUpdated(acct,updateAcct,'BillingCountry',ecom,'Country__c', changed);
         changed = fieldUpdated(acct,updateAcct,'ShippingStreet',ecom,'StreetAddress__c', changed);
         changed = fieldUpdated(acct,updateAcct,'ShippingCity',ecom,'City__c', changed);
         changed = fieldUpdated(acct,updateAcct,'ShippingState',ecom,'State__c', changed);
         changed = fieldUpdated(acct,updateAcct,'ShippingPostalCode',ecom,'PostalCode__c', changed);
         changed = fieldUpdated(acct,updateAcct,'ShippingCountry',ecom,'Country__c', changed);
      }
      /*
      changed = fieldUpdated(acct,updateAcct,'BillingStreet',ecom,'BillingAddress__Street__s', changed);
      changed = fieldUpdated(acct,updateAcct,'BillingCity',ecom,'BillingAddress__City__s', changed);
      changed = fieldUpdated(acct,updateAcct,'BillingState',ecom,'BillingAddress__StateCode__s', changed);
      changed = fieldUpdated(acct,updateAcct,'BillingPostalCode',ecom,'BillingAddress__PostalCode__s', changed);
      changed = fieldUpdated(acct,updateAcct,'BillingCountry',ecom,'BillingAddress__CountryCode__s', changed);
      changed = fieldUpdated(acct,updateAcct,'ShippingStreet',ecom,'ShippingAddress__Street__s', changed);
      changed = fieldUpdated(acct,updateAcct,'ShippingCity',ecom,'ShippingAddress__City__s', changed);
      changed = fieldUpdated(acct,updateAcct,'ShippingState',ecom,'ShippingAddress__StateCode__s', changed);
      changed = fieldUpdated(acct,updateAcct,'ShippingPostalCode',ecom,'ShippingAddress__PostalCode__s', changed);
      changed = fieldUpdated(acct,updateAcct,'ShippingCountry',ecom,'ShippingAddress__CountryCode__s', changed);
      */
      changed = fieldUpdated(acct,updateAcct,'LegalAddress__Street__s',ecom,'LegalAddress__Street__s', changed);
      changed = fieldUpdated(acct,updateAcct,'LegalAddress__City__s',ecom,'LegalAddress__City__s', changed);
      changed = fieldUpdated(acct,updateAcct,'LegalAddress__StateCode__s',ecom,'LegalAddress__StateCode__s', changed);
      changed = fieldUpdated(acct,updateAcct,'LegalAddress__PostalCode__s',ecom,'LegalAddress__PostalCode__s', changed);
      changed = fieldUpdated(acct,updateAcct,'LegalAddress__CountryCode__s',ecom,'LegalAddress__CountryCode__s', changed);
          
      changed = fieldUpdated(acct,updateAcct,'EnterpriseAAID__c',ecom,'EnterpriseAAID__c', changed);
      changed = fieldUpdated(acct,updateAcct,'Employees__c', Integer.valueOf(ecom.NumberOfEmployees__c), changed);
      changed = fieldUpdated(acct,updateAcct,'NumberOfEmployees', Integer.valueOf(ecom.NumberOfEmployees__c), changed);
      // TODO - need to verify what industry type is actually returning
      //changed = fieldUpdated(acct,updateAcct,'Industry',wrap.ecom,'IndustryType__c', changed);
      return changed;
   } // setFromEcom
    
   public static void checkAuthorizedContact(Account acct, Contact ctct, EcomWrap wrap) {
      System.debug('checkAuthorizedContact');
      Contact ctctMatch = null;
      if (ctct != null && ctct.LastName == wrap.ecom.AuthorizingLastName__c && ctct.Email == wrap.ecom.AuthorizingEmail__c) {
         ctctMatch = ctct;
      }
      if (ctctMatch == null && acct != null) {
         // look through the existing contacts
         Contact[] ctcts = [Select Id, FirstName, LastName, Title, Email, Phone from Contact where AccountId=:acct.Id order by LastModifiedDate desc limit 20];
         for (Contact chkCtct : ctcts) {
            // don't need to check the contact we already have
            if (ctct == null || chkCtct.Id != ctct.Id) {
                if (chkCtct.LastName == wrap.ecom.AuthorizingLastName__c && chkCtct.Email == wrap.ecom.AuthorizingEmail__c) {
                    ctctMatch = chkCtct;
                }
            }
         }
      } // if (!matchFound && acct != null
      // create a new one if no match found
      if (ctctMatch == null && acct != null) {
         ctctMatch = new Contact(AccountId=acct.Id);
      }
      if (ctctMatch != null) {
          ctctMatch.FirstName = wrap.ecom.AuthorizingFirstName__c;
          ctctMatch.LastName = wrap.ecom.AuthorizingLastName__c;
          ctctMatch.Title = wrap.ecom.AuthorizingTitle__c;
          ctctMatch.Email = wrap.ecom.AuthorizingEmail__c;
          ctctMatch.Phone = wrap.ecom.AuthorizingPhone__c;
      }
      
      System.debug('checkAuthorizedContact ctctMatch='+ctctMatch);
      if (ctctMatch.Id != null) {
         StringHelper.addToProcessNotes(wrap.ecom, 'checkAuthorizedContact updating a contact for Authorized Contact');
         ctctUpdateMap.put(ctctMatch.Id,ctct);
      } else {
         StringHelper.addToProcessNotes(wrap.ecom, 'checkAuthorizedContact inserting a contact for Authorized Contact');
         ctctInserts.add(ctctMatch);
      }
   } // checkAuthorizedContact
    
   // see if the curState is before or after the targetStage
   public static String checkStage(String curStage, String targetStage) {
      String retStage = curStage;
      Integer curStageRank = getStageRanking(curStage);
      Integer tarStageRank = getStageRanking(targetStage); 
      System.debug('checkStage curStageRank='+curStageRank+' tarStageRank='+tarStageRank);
      if (tarStageRank > curStageRank) {
         retStage = targetStage;
      }
      
      return retStage;
   } // checkStage
    
   public static Integer getStageRanking(String stageName) {
      Integer ranking=0;
      if (String.isNotBlank(stageName)) {
         Map<String,MarketingStage__mdt> stageMap = DG_LMF_Service.getStageMap();
         if (stageMap != null && stageMap.containsKey(stageName)) {
            MarketingStage__mdt stage = stageMap.get(stageName);
            ranking = Integer.valueOf(stage.SortOrder__c);
         }
      } // if (String.isNotBlank(stageName
      return ranking;
   } // getStageRanking
    
   public static Boolean fieldUpdated(SObject rec, SObject updateRec, String recFldName, Ecommerce__c ecom, String ecomFldName, Boolean p_changed) {
      Boolean changed = (ecom.get(ecomFldName) != null && ecom.get(ecomFldName) != rec.get(recFldName));
      if (changed) {
         // TODO - do we need to do any formatting?
         updateRec.put(recFldName, ecom.get(ecomFldName));
      }
      return (changed || p_changed);
   } // fieldUpdated

   // to compare Integer fields
   public static Boolean fieldUpdated(SObject rec, SObject updateRec, String recFldName, Integer checkValue, Boolean p_changed) {
      Integer recValue = Integer.valueOf(rec.get(recFldName));
      Boolean changed = (checkValue != null && recValue != checkValue);
      if (changed) {
         updateRec.put(recFldName, checkValue);
      }
      return (changed || p_changed);
   } // fieldUpdated
} // class EcomMethods